class ParseArticleContentJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find(article_id)
    return unless article&.blog_url

    Rails.logger.info "Parsing content for article: #{article.blog_url}"
    
    content = parse_article_content(article.blog_url)
    
    if content
      article.update!(content: content)
      Rails.logger.info "Successfully parsed and saved content for article ID: #{article.id}"
    else
      Rails.logger.error "Failed to parse content for article: #{article.blog_url}"
    end
  rescue => e
    Rails.logger.error "ParseArticleContentJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  private

  def parse_article_content(url)
    require 'nokogiri'
    require 'net/http'
    require 'uri'

    begin
      # Fetch HTML content from URL
      response = Net::HTTP.get_response(URI(url))

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error "Error: Failed to fetch URL #{url} (#{response.code})"
        return nil
      end

      html_content = response.body
      parse_html(html_content)
    rescue => e
      Rails.logger.error "Error fetching URL #{url}: #{e.message}"
      nil
    end
  end

  def parse_html(html_content)
    # Parse HTML with Nokogiri
    doc = Nokogiri::HTML(html_content)

    # Find the body element, fallback to entire document if no body
    body = doc.at('body') || doc

    # Remove script and style elements completely
    body.search('script, style, noscript').remove

    # Remove header and design elements
    body.search('header, nav, footer, aside, .header, .nav, .navigation, .sidebar, .menu, .breadcrumb, .pagination, .advertisement, .ad, .social, .share, .comment-form, .search-form, #header, #nav, #navigation, #sidebar, #menu, #footer').remove

    # Remove elements with common design-related classes and IDs
    body.search('[class*="nav"], [class*="menu"], [class*="header"], [class*="footer"], [class*="sidebar"], [class*="banner"], [class*="ad"], [class*="social"], [class*="share"], [class*="widget"], [class*="meta"], [id*="nav"], [id*="menu"], [id*="header"], [id*="footer"], [id*="sidebar"]').remove

    # Remove additional design and navigation elements
    body.search('button, input, select, textarea, form, .button, .btn, .form, .input, .search, .filter, .sort, .dropdown, .modal, .popup, .overlay, .tooltip, .alert, .notification, .cookie, .gdpr').remove

    # Remove comments and interactive elements
    body.search('.comments, .comment, .reply, .votes, .rating, .tags, .categories, .author-info, .date, .timestamp, .byline, .caption, .credit').remove

    # Try to find main content areas first
    main_content = body.at('main, article, [role="main"], .main, .content, .post, .entry, #main, #content') || body

    # Extract text content from main content area
    text_content = main_content.text

    # Clean up whitespace
    text_content.gsub(/\s+/, ' ').strip
  end
end
