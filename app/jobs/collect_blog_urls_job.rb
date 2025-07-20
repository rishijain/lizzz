class CollectBlogUrlsJob < ApplicationJob
  queue_as :default

  def perform(blog_site_id)
    blog_site = BlogSite.find(blog_site_id)
    return unless blog_site

    blog_site.update!(discovery_status: 'discovering')
    Rails.logger.info "Starting URL collection for blog site: #{blog_site.url}"
    
    total_urls = collect_blog_urls(blog_site)
    
    if total_urls > 0
      blog_site.update!(
        discovery_status: 'success',
        discovered_count: total_urls
      )
    else
      blog_site.update!(discovery_status: 'needs_selector')
    end
    
  rescue => e
    Rails.logger.error "CollectBlogUrlsJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    blog_site.update!(discovery_status: 'failed') if blog_site
    raise
  end

  private

  def collect_blog_urls(blog_site)
    require 'nokogiri'
    require 'net/http'
    require 'uri'
    require 'set'

    seen_urls = Set.new
    current_page = 1
    next_page_url = blog_site.url
    
    while next_page_url && current_page <= 12
      Rails.logger.info "Processing page #{current_page}: #{next_page_url}"
      
      page_urls = scrape_page(next_page_url, blog_site)
      
      # Create Article records for unique URLs
      unique_urls = page_urls.select { |url| !seen_urls.include?(url) }
      unique_urls.each { |url| seen_urls.add(url) }
      
      create_articles(unique_urls, blog_site)
      
      Rails.logger.info "Added #{unique_urls.length} unique URLs (#{page_urls.length - unique_urls.length} duplicates)"
      
      next_page_url = get_next_page_url(next_page_url, current_page, blog_site.url)
      current_page += 1
    end
    
    Rails.logger.info "Found #{seen_urls.length} total unique blog posts for #{blog_site.url}"
    seen_urls.length
  end

  def scrape_page(page_url, blog_site)
    urls = []
    seen_on_page = Set.new
    
    begin
      response = Net::HTTP.get_response(URI(page_url))
      
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error "Error fetching page #{page_url}: #{response.code}"
        return urls
      end
      
      doc = Nokogiri::HTML(response.body)
      
      # Extract blog post URLs - try custom selector first, then fallback to general approach
      blog_links = extract_links_with_strategy(doc, blog_site)
      
      base_uri = URI(blog_site.url)
      
      blog_links.each do |href|
        next if href.nil? || href.empty?
        
        Rails.logger.debug "Processing link: #{href}"
        
        # Convert relative URLs to absolute
        begin
          full_url = URI.join(blog_site.url, href).to_s
          Rails.logger.debug "Full URL: #{full_url}"
          
          # Skip if we've already seen this URL on this page
          if seen_on_page.include?(full_url)
            Rails.logger.debug "Skipping duplicate URL: #{full_url}"
            next
          end
          
          # If using custom selector, trust the results more (only basic filtering)
          # Otherwise apply strict blog post filtering
          if blog_site.custom_selector.present?
            if looks_like_valid_url?(full_url, base_uri.host)
              Rails.logger.debug "Valid URL with custom selector: #{full_url}"
              seen_on_page.add(full_url)
              urls << full_url
            else
              Rails.logger.debug "Filtered out by looks_like_valid_url: #{full_url}"
            end
          else
            # Apply strict filtering for automatic detection
            if looks_like_blog_post?(full_url, base_uri.host)
              Rails.logger.debug "Valid blog post URL: #{full_url}"
              seen_on_page.add(full_url)
              urls << full_url
            else
              Rails.logger.debug "Filtered out by looks_like_blog_post: #{full_url}"
            end
          end
        rescue URI::InvalidURIError => e
          Rails.logger.debug "Invalid URI error for #{href}: #{e.message}"
          next
        end
      end
      
      Rails.logger.info "Found #{urls.length} potential blog post URLs"
      
    rescue => e
      Rails.logger.error "Error scraping page #{page_url}: #{e.message}"
    end
    
    urls
  end

  def extract_links_with_strategy(doc, blog_site)
    # Strategy 1: Use custom selector if provided
    if blog_site.custom_selector.present?
      Rails.logger.info "Using custom selector: #{blog_site.custom_selector}"
      links = []
      
      # Smart link extraction within the custom selector
      container_elements = doc.css(blog_site.custom_selector)
      
      if container_elements.any?
        Rails.logger.info "Found #{container_elements.length} container(s) matching selector"
        
        container_elements.each do |container|
          # Strategy 1a: Direct links in the container
          direct_links = container.css('a[href]')
          direct_links.each { |link| links << link['href'] }
          
          # Strategy 1b: Links in immediate children (like .post, .article, etc.)
          immediate_children = container.children.select(&:element?)
          immediate_children.each do |child|
            child.css('a[href]').each { |link| links << link['href'] }
          end
          
          # Strategy 1c: Look for common blog post wrapper patterns
          blog_post_patterns = [
            '.post', '.article', '.entry', '.blog-post', '.content',
            '[class*="post"]', '[class*="article"]', '[class*="entry"]',
            'article', 'div[class*="item"]', 'li'
          ]
          
          blog_post_patterns.each do |pattern|
            container.css(pattern).each do |element|
              element.css('a[href]').each { |link| links << link['href'] }
            end
          end
        end
        
        # Remove duplicates while preserving order
        links = links.uniq
        Rails.logger.info "Found #{links.length} unique links using intelligent extraction"
      else
        Rails.logger.warn "No elements found matching custom selector: #{blog_site.custom_selector}"
      end
      
      return links if links.any?
    end

    # Strategy 2: Try common blog patterns
    Rails.logger.info "Using automatic blog post detection"
    doc.css('a[href]').map { |link| link['href'] }
  end

  def looks_like_valid_url?(url, host)
    uri = URI(url)
    
    # Must be same host
    unless uri.host == host
      Rails.logger.debug "Rejected #{url}: different host (#{uri.host} vs #{host})"
      return false
    end
    
    # Basic filtering - skip static files and obviously non-content URLs
    path = uri.path.downcase
    
    # Skip static files
    if path.match?(/\.(css|js|png|jpg|jpeg|gif|svg|ico|pdf|zip)$/i)
      Rails.logger.debug "Rejected #{url}: static file"
      return false
    end
    
    # Skip root and empty paths
    if path == '/' || path.empty?
      Rails.logger.debug "Rejected #{url}: root or empty path"
      return false
    end
    
    # Skip obviously admin/system pages
    if path.match?(/^\/?(admin|login|signup|404|500)$/i)
      Rails.logger.debug "Rejected #{url}: admin/system page"
      return false
    end
    
    # Skip directory-like paths (ending with /) unless they look like blog posts
    # Allow paths that have date patterns or meaningful content after the date
    if path.match?(/\/$/)
      # Allow if it matches common blog post patterns:
      # - /YYYY/MM/DD/post-title/
      # - /YYYY/MM/post-title/  
      # - Has substantial content after date (more than just numbers)
      unless path.match?(/\/\d{4}\/\d{2}\/(\d{2}\/)?[\w\-]+\/$/) || path.match?(/\/\d{4}\/\d{2}\/[\w\-]+\/$/)
        Rails.logger.debug "Rejected #{url}: directory-like path without content"
        return false
      end
    end
    
    Rails.logger.debug "Accepted #{url}: passed all validation checks"
    true
  end

  def looks_like_blog_post?(url, host)
    uri = URI(url)
    
    # Must be same host
    return false unless uri.host == host
    
    # Common blog post patterns
    path = uri.path.downcase
    
    # Skip common non-blog pages
    return false if path.match?(/\.(css|js|png|jpg|jpeg|gif|svg|ico|pdf|zip)$/i)
    return false if path.match?(/^\/?(about|contact|privacy|terms|search|admin|login|signup|404|500)$/i)
    return false if path == '/' || path.empty?
    
    # Skip tag, category, author, and archive pages
    return false if path.match?(/\/(tags?|categories?|authors?|archive)\//)
    return false if path.match?(/\/page\d*\//)  # Pagination pages
    return false if path.match?(/\?page=/)      # Query-based pagination
    
    # Skip directory-like paths (ending with /)
    return false if path.match?(/\/$/)
    
    # Look for actual blog post patterns
    return true if path.match?(/\/\d{4}\/\d{2}\/\d{2}\//)  # Date-based URLs (YYYY/MM/DD)
    return true if path.match?(/\/\d{4}\/\d{2}\//)         # Date-based URLs (YYYY/MM)
    return true if path.match?(/\.html?$/)                 # HTML files
    
    # For paths like /blog/post-title or /news/article-title
    # Must have at least 3 segments and not end with common non-post patterns
    segments = path.split('/').reject(&:empty?)
    if segments.length >= 2
      # First segment should be blog-related
      return true if segments[0].match?(/^(blog|post|article|news)$/) && segments[1] && !segments[1].match?(/^(tags?|categories?|authors?|archive|page)$/)
    end
    
    false
  end

  def create_articles(urls, blog_site)
    urls.each do |url|
      # Check if article already exists
      existing_article = Article.find_by(blog_url: url, blog_site: blog_site)
      next if existing_article
      
      article = Article.create!(
        blog_site: blog_site,
        blog_url: url,
        source_type: 'discovered',
        content: nil  # Will be populated by ParseArticleContentJob
      )
      
      # Queue job to parse the article content
      ParseArticleContentJob.perform_later(article.id)
    end
  end

  def get_next_page_url(current_url, current_page, base_url)
    # Try common pagination patterns
    base_uri = URI(base_url)
    
    # Pattern 1: /blog/page2/, /blog/page3/, etc.
    next_page_num = current_page + 1
    next_url = "#{base_url.chomp('/')}/page#{next_page_num}/"
    
    if page_exists?(next_url)
      return next_url
    end
    
    # Pattern 2: /blog/page/2/, /blog/page/3/, etc.
    next_url = "#{base_url.chomp('/')}/page/#{next_page_num}/"
    
    if page_exists?(next_url)
      return next_url
    end
    
    # Pattern 3: ?page=2, ?page=3, etc.
    next_url = "#{base_url}?page=#{next_page_num}"
    
    if page_exists?(next_url)
      return next_url
    end
    
    Rails.logger.info "No more pages found"
    nil
  end

  def page_exists?(url)
    begin
      response = Net::HTTP.get_response(URI(url))
      if response.is_a?(Net::HTTPSuccess)
        Rails.logger.info "Next page found: #{url}"
        return true
      else
        return false
      end
    rescue => e
      Rails.logger.error "Error checking page existence: #{e.message}"
      return false
    end
  end
end
