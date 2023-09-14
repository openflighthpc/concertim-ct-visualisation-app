# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  protect_from_forgery unless: -> { request.format.json? }
  skip_before_action :verify_authenticity_token, only: [:create]

  respond_to :html, :json

  # GET /resource/sign_in
  def new
    if failed_login?
      # We're being rendered after a failed login attempt.  Not sure why this
      # is necessary, devise ought to do this itself. Perhaps something to do
      # with `Devise::FailureApp#is_flashing_format?` ?
      flash.now[:alert] = t('devise.failure.invalid', authentication_keys: 'username')
    end
    super
  end

  # POST /resource/sign_in
  # def create
  #   super { |resource| @resource = resource }
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private

  def failed_login?
    params[:action] == 'create' && request.format.html? && !signed_in?
  end
end
