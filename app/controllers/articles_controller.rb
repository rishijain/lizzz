class ArticlesController < ApplicationController
  before_action :require_login
  before_action :set_blog_site
  before_action :set_article, only: [:show, :generate_summary]

  def index
    @articles = @blog_site.articles.manual.order(created_at: :desc)
  end

  def create
    @article = @blog_site.articles.build(article_params)
    @article.source_type = 'manual'

    if @article.save
      # Queue background job to parse content
      ParseArticleContentJob.perform_later(@article.id)
      redirect_to blog_site_articles_path(@blog_site), notice: 'Article URL saved! Content is being parsed in the background.'
    else
      render :new
    end
  end

  def new
    @article = @blog_site.articles.build
  end

  def show
  end

  def generate_summary
    if @article.content.present?
      @article.update(summary_status: 'generating')
      GenerateSummaryJob.perform_later(@article.id)
      redirect_to blog_site_articles_path(@blog_site), notice: 'Summary generation started!'
    else
      redirect_to blog_site_articles_path(@blog_site), alert: 'Cannot generate summary - article content not yet parsed.'
    end
  end

  private

  def set_blog_site
    @blog_site = current_user.blog_sites.find(params[:blog_site_id])
  end

  def set_article
    @article = @blog_site.articles.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :blog_url)
  end
end
