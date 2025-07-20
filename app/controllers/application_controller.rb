class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  def logged_in?
    !!current_user
  end
  helper_method :logged_in?

  def require_login
    unless logged_in?
      redirect_to signin_path, alert: "You must be logged in to access this page."
    end
  end

  def current_user_admin?
    current_user&.admin?
  end
  helper_method :current_user_admin?

  def require_admin
    unless current_user_admin?
      redirect_to blog_sites_path, alert: "Access denied. Admin privileges required."
    end
  end
end
