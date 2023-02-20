class Api::V1::ApplicationController < Api::ApplicationController

  private

  def success_response(object, message = [])
    render :json => {"success" => "true", "action" => params[:action], "id" => object[:id], "data" => message}
  end

  def failure_response(object)
    render json: {errors: object.errors.as_json}
  end

  def error_for(object_name, message: 'not found', status: 404)
    render :json => {"success" => "false", "errors" => "#{object_name.capitalize} #{params[:id]} #{message}"}, status: status
  end
end
