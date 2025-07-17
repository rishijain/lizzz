class CollectBlogUrlsJob < ApplicationJob
  queue_as :default

  def perform(blog_site_id)
    blog_site = BlogSite.find(blog_site_id)
    return unless blog_site

    Rails.logger.info "Starting URL collection for blog site: #{blog_site.url}"
    
    collect_blog_urls(blog_site)
  rescue => e
    Rails.logger.error "CollectBlogUrlsJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
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
      
      page_urls = scrape_page(next_page_url, blog_site.url)
      
      # Create Article records for unique URLs
      unique_urls = page_urls.select { |url| !seen_urls.include?(url) }
      unique_urls.each { |url| seen_urls.add(url) }
      
      create_articles(unique_urls, blog_site)
      
      Rails.logger.info "Added #{unique_urls.length} unique URLs (#{page_urls.length - unique_urls.length} duplicates)"
      
      next_page_url = get_next_page_url(next_page_url, current_page, blog_site.url)
      current_page += 1
    end
    
    Rails.logger.info "Found #{seen_urls.length} total unique blog posts for #{blog_site.url}"
  end

  def scrape_page(page_url, base_url)
    urls = []
    seen_on_page = Set.new
    
    begin
      response = Net::HTTP.get_response(URI(page_url))
      
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error "Error fetching page #{page_url}: #{response.code}"
        return urls
      end
      
      doc = Nokogiri::HTML(response.body)
      
      # Extract blog post URLs - look for links that could be blog posts
      blog_links = doc.css('a[href]').map { |link| link['href'] }
      
      base_uri = URI(base_url)
      
      blog_links.each do |href|
        next if href.nil? || href.empty?
        
        # Convert relative URLs to absolute
        begin
          full_url = URI.join(base_url, href).to_s
          
          # Skip if we've already seen this URL on this page
          next if seen_on_page.include?(full_url)
          
          # Filter for URLs that look like blog posts
          if looks_like_blog_post?(full_url, base_uri.host)
            seen_on_page.add(full_url)
            urls << full_url
          end
        rescue URI::InvalidURIError
          # Skip invalid URLs
          next
        end
      end
      
      Rails.logger.info "Found #{urls.length} potential blog post URLs"
      
    rescue => e
      Rails.logger.error "Error scraping page #{page_url}: #{e.message}"
    end
    
    urls
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
      
      Article.create!(
        blog_site: blog_site,
        blog_url: url,
        content: nil  # Will be populated later when content is scraped
      )
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
