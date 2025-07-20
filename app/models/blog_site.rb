class BlogSite < ApplicationRecord
  belongs_to :user
  has_many :articles, dependent: :destroy

  validates :name, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
end
