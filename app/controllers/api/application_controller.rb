#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

class Api::ApplicationController < ActionController::API
  include ControllerConcerns::Authentication
  include ControllerConcerns::Authorization
  include ActionController::MimeResponds
  # respond_to :json

  # Make an attempt to respond to any exceptions with a JSON:API errors
  # response.
  #
  # This doesn't quite work as some exceptions such as
  # ActionController::RoutingError and AbstractController::ActionNotFound
  # cannot be caught by `rescue_from`.
  #
  # This error handler can be overridden by registering an error handler for a
  # more specific exception after this one is registered.
  rescue_from Exception do |exception|
    error, status = error_and_status_from(exception)
    render json: {errors: [error]}, status: status
  end

  rescue_from ActionController::ParameterMissing, ActionController::UnfilteredParameters do |exception|
    render json: {status: 400, error: exception.message}, status: :bad_request
  end

  rescue_from ActiveRecord::RecordNotFound do
    render json: {error: "not found"}, status: :not_found
  end

  rescue_from CanCan::AccessDenied do |exception|
    error, status = error_and_status_from(exception, status: :forbidden)
    render json: {errors: [error]}, status: status
  end

  private

  def error_and_status_from(exception, status: nil)
    if status.present?
      status_sym = status
    else
      status_map = Rails.application.config.action_dispatch.rescue_responses
      status_sym = status_map.fetch(exception.class.name.to_s, :internal_server_error)
    end
    status_code = ::Rack::Utils::SYMBOL_TO_STATUS_CODE[status_sym]
    title = I18n.t("api.errors.title.#{exception.class.name.underscore}", default: exception.class.name.to_s)
    description =
      error = {status: status_code.to_s, title: title, description: exception.message}
    if Rails.env.development?
      backtrace = Rails.backtrace_cleaner.clean(exception.backtrace)
      error[:meta] = {backtrace: backtrace.join("\n")}
    end
    [error, status_sym]
  end
end
