class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :authenticate_user!
  before_action :set_locale

  # before_filter :configure_permitted_parameters, if: :devise_controller?

  # def configure_permitted_parameters
  #   devise_parameter_sanitizer.for(:account_update) { |u|
  #     u.permit(:password, :password_confirmation, :current_password)
  #   }
  # end

  def set_locale
    current_user_locale = current_user ? current_user.locale : nil
    I18n.locale = params[:locale] || current_user_locale || I18n.default_locale
  end

  # Verifies if the currently logged in user is an admin. Called from child controllers.
  def verify_admin
    if current_user
      if current_user.admin?
        return
      else
        flash[:error] = "You must be an admin to perform this task!"
      end
    else
      flash[:error] = "No user logged in!"
    end
    redirect_to(root_path)
  end
end
