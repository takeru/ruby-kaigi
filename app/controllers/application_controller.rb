# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def current_user
    if @current_user.nil?
      if session[:user_id]
        @current_user = User.get_by_id(session[:user_id])
      end
      @current_user ||= :false
    end
    return @current_user==:false ? nil : @current_user
  end

  def logged_in?
    current_user != nil
  end

  helper_method :current_user, :logged_in?
end
