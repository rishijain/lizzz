class AddBlogSiteToArticles < ActiveRecord::Migration[8.0]
  def change
    add_reference :articles, :blog_site, null: false, foreign_key: true
    add_column :articles, :blog_url, :string
  end
end
