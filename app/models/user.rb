class User < ApplicationRecord
  has_secure_password
  has_many :blog_sites, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :maximum_blog_sites

  def admin?
    admin
  end

  private

  def maximum_blog_sites
    # Admins can have unlimited blog sites
    return if admin?
    
    if blog_sites.size > 3
      errors.add(:blog_sites, "cannot have more than 3 blog sites")
    end
  end
end
