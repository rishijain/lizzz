class ParseArticleContentJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find(article_id)
    return unless article&.blog_url

    Rails.logger.info "Parsing content for article: #{article.blog_url}"

    content = parse_article_content(article.blog_url)

    if content
      article.update!(content: content)
      article.save_embedding
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

    # Look specifically for content inside article.post section.post-content
    post_content = doc.at('article.post section.post-content')

    # If no article.post section.post-content found, return nil or empty string
    unless post_content
      Rails.logger.warn "No article.post section.post-content found in HTML"
      return ""
    end

    # Remove code blocks from the post content
    post_content.search('pre, code, .highlight, .code, .sourceCode, .codehilite, .syntax-highlight, .language-').remove

    # Extract text content from post-content area only
    text_content = post_content.text

    # Clean up whitespace
    text_content.gsub(/\s+/, ' ').strip
  end
end
