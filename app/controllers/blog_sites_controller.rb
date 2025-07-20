class BlogSitesController < ApplicationController
  before_action :require_login
  before_action :set_blog_site, only: [:show, :edit, :update, :destroy]

  def index
    @blog_sites = current_user.blog_sites
  end

  def show
  end

  def new
    if current_user.blog_sites.count >= 3
      redirect_to blog_sites_path, alert: "You can only have up to 3 blog sites."
      return
    end
    @blog_site = current_user.blog_sites.build
  end

  def create
    if current_user.blog_sites.count >= 3
      redirect_to blog_sites_path, alert: "You can only have up to 3 blog sites."
      return
    end

    @blog_site = current_user.blog_sites.build(blog_site_params)

    if @blog_site.save
      CollectBlogUrlsJob.perform_later(@blog_site.id)
      redirect_to @blog_site, notice: 'Blog site was successfully created and URL collection started.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @blog_site.update(blog_site_params)
      redirect_to @blog_site, notice: 'Blog site was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @blog_site.destroy
    redirect_to blog_sites_url, notice: 'Blog site was successfully deleted.'
  end

  private

  def set_blog_site
    @blog_site = current_user.blog_sites.find(params[:id])
  end

  def blog_site_params
    params.require(:blog_site).permit(:name, :url)
  end
end
