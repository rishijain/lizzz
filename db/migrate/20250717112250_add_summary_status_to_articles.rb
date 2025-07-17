class AddSummaryStatusToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :summary_status, :string
    add_index :articles, :summary_status
  end
end
