# frozen_string_literal: true

class Uma::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  protected

  # We only want to require a password check when changing the password.
  def update_resource(resource, params)
    if params.key?(:password)
      resource.update_with_password(params)
    else
      resource.update(params)
    end
  end

  def account_update_params
    super.tap do |params|
      if params[:password].blank? && params[:password_confirmation].blank?
        params.delete :password
        params.delete :password_confirmation
        params.delete :current_password
      end
    end
  end

  # Use the application root path not the engine root path.
  def signed_in_root_path(resource)
    Rails.application.routes.url_helpers.root_path
  end

  private

  def configure_permitted_parameters
    update_attrs = [:firstname, :surname]
    devise_parameter_sanitizer.permit :account_update, keys: update_attrs
  end
end