class BlogSite < ApplicationRecord
  has_many :articles, dependent: :destroy
end
