class ArticlesController < ApplicationController
  def index
    @articles = Article.manual.order(created_at: :desc)
  end

  def create
    @article = Article.new(article_params)
    @article.source_type = 'manual'

    if @article.save
      # Queue background job to parse content
      ParseArticleContentJob.perform_later(@article.id)
      redirect_to articles_path, notice: 'Article URL saved! Content is being parsed in the background.'
    else
      @blog_sites = BlogSite.all
      render :new
    end
  end

  def new
    @article = Article.new
    @blog_sites = BlogSite.all
  end

  def show
    @article = Article.find(params[:id])
  end

  def generate_summary
    @article = Article.find(params[:id])

    if @article.content.present?
      GenerateSummaryJob.perform_later(@article.id)
      redirect_to articles_path, notice: 'Summary generation started!'
    else
      redirect_to articles_path, alert: 'Cannot generate summary - article content not yet parsed.'
    end
  end

  private

  def article_params
    params.require(:article).permit(:title, :blog_url, :blog_site_id)
  end
end
