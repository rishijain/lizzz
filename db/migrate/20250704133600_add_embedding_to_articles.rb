class AddEmbeddingToArticles < ActiveRecord::Migration[8.0]
  def change
    # pgvector, MariaDB, and MySQL
    add_column :articles, :embedding, :vector # dimensions
  end
end
