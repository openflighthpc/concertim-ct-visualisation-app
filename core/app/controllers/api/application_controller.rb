class Api::ApplicationController < ActionController::API
  include Emma::ControllerConcerns::Authentication
  include ActionController::MimeResponds
  # respond_to :json

  rescue_from ActionController::ParameterMissing, ActionController::UnfilteredParameters do |exception|
    render json: {status: 400, error: exception.message}, status: :bad_request
  end

  rescue_from ActiveRecord::RecordNotFound do
    render json: {error: "not found"}, status: :not_found
  end
end
