class AddDiscoveryFieldsToBlogSites < ActiveRecord::Migration[8.0]
  def change
    add_column :blog_sites, :custom_selector, :string
    add_column :blog_sites, :discovery_status, :string, default: 'pending'
    add_column :blog_sites, :discovered_count, :integer, default: 0
  end
end
