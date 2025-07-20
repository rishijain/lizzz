class AddUserToBlogSites < ActiveRecord::Migration[8.0]
  def change
    add_reference :blog_sites, :user, null: false, foreign_key: true
  end
end
