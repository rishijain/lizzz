class BlogSite < ApplicationRecord
  belongs_to :user
  has_many :articles, dependent: :destroy

  validates :name, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }

  enum :discovery_status, {
    pending: 'pending',
    discovering: 'discovering',
    success: 'success',
    failed: 'failed',
    needs_selector: 'needs_selector'
  }

  def discovery_complete?
    success? || failed?
  end

  def needs_custom_selector?
    needs_selector?
  end
end
