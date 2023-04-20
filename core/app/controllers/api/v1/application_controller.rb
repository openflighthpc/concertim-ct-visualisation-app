class Api::V1::ApplicationController < Api::ApplicationController

  private

  def error_for(object_name, message: 'not found', status: 404)
    render :json => {"success" => "false", "errors" => "#{object_name.capitalize} #{params[:id]} #{message}"}, status: status
  end
end
