#
# Mixin for functionality pertaining to authentication
#
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  def after_sign_out_path_for(resource)
    stored_location_for(resource) || '/users/sign_in'
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || '/'
  end
end

