class CreateBlogSites < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_sites do |t|
      t.string :url
      t.string :name

      t.timestamps
    end
  end
end
