class Api::ApplicationController < ActionController::API
  # respond_to :json
  include Emma::ControllerConcerns::Authentication
end
