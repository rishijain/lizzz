class BlogSitesController < ApplicationController
  before_action :set_blog_site, only: [:show, :edit, :update, :destroy]

  def index
    @blog_sites = BlogSite.all
  end

  def show
  end

  def new
    @blog_site = BlogSite.new
  end

  def create
    @blog_site = BlogSite.new(blog_site_params)

    if @blog_site.save
      redirect_to @blog_site, notice: 'Blog site was successfully created.'
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
    @blog_site = BlogSite.find(params[:id])
  end

  def blog_site_params
    params.require(:blog_site).permit(:name, :url)
  end
end
