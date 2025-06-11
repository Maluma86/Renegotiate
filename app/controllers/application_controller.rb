class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[
      company_name role contact contact_email
    ])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[
      company_name role contact contact_email
    ])
  end
end
