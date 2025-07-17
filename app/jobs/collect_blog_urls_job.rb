class CollectBlogUrlsJob < ApplicationJob
  queue_as :default

  def perform(blog_site_id)
    blog_site = BlogSite.find(blog_site_id)
    return unless blog_site

    # TODO: Add logic to collect blog URLs from blog_site.url
    # This will parse the blog homepage and extract individual blog post URLs
    # Then create Article records with blog_url and blog_site_id
  rescue => e
    Rails.logger.error "CollectBlogUrlsJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
