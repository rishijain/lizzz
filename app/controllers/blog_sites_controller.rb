class BlogSitesController < ApplicationController
  before_action :require_login
  before_action :set_blog_site, only: [:show, :edit, :update, :destroy, :retry_discovery, :discovered_urls, :clear_discovered_urls]

  def index
    if current_user_admin?
      @blog_sites = BlogSite.includes(:user).all
    else
      @blog_sites = current_user.blog_sites
    end
  end

  def show
  end

  def new
    if !current_user_admin? && current_user.blog_sites.count >= 3
      redirect_to blog_sites_path, alert: "You can only have up to 3 blog sites."
      return
    end
    @blog_site = current_user.blog_sites.build
  end

  def create
    if !current_user_admin? && current_user.blog_sites.count >= 3
      redirect_to blog_sites_path, alert: "You can only have up to 3 blog sites."
      return
    end

    @blog_site = current_user.blog_sites.build(blog_site_params)

    if @blog_site.save
      CollectBlogUrlsJob.perform_later(@blog_site.id)
      redirect_to @blog_site, notice: 'Blog site was successfully created! We are discovering blog post URLs in the background.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @blog_site.update(blog_site_params)
      # If custom_selector was updated, retry discovery
      if params[:blog_site][:custom_selector].present? && @blog_site.needs_custom_selector?
        @blog_site.update!(discovery_status: 'pending')
        CollectBlogUrlsJob.perform_later(@blog_site.id)
        redirect_to @blog_site, notice: 'Blog site was successfully updated! Retrying URL discovery with custom selector.'
      else
        redirect_to @blog_site, notice: 'Blog site was successfully updated.'
      end
    else
      render :edit
    end
  end

  def discovered_urls
    # Show all articles for now to debug - we can filter by source_type later
    @articles = @blog_site.articles.order(:created_at)
    @discovered_articles = @blog_site.articles.where(source_type: 'discovered').order(:created_at)
  end

  def clear_discovered_urls
    @blog_site.articles.where(source_type: 'discovered').destroy_all
    @blog_site.update!(discovery_status: 'pending', discovered_count: 0)
    redirect_to @blog_site, notice: 'All discovered URLs have been cleared. You can now retry discovery with a custom selector.'
  end

  def retry_discovery
    @blog_site.update!(discovery_status: 'pending')
    CollectBlogUrlsJob.perform_later(@blog_site.id)
    redirect_to @blog_site, notice: 'URL discovery restarted!'
  end

  def destroy
    @blog_site.destroy
    redirect_to blog_sites_url, notice: 'Blog site was successfully deleted.'
  end

  private

  def set_blog_site
    if current_user_admin?
      @blog_site = BlogSite.find(params[:id])
    else
      @blog_site = current_user.blog_sites.find(params[:id])
    end
  end

  def blog_site_params
    params.require(:blog_site).permit(:name, :url, :custom_selector)
  end
end
