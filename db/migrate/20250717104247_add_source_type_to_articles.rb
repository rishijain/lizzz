class AddSourceTypeToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :source_type, :string, default: 'scraped'
    add_index :articles, :source_type
  end
end
