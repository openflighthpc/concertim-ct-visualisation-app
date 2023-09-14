class Api::V1::ApplicationController < Api::ApplicationController

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def error_for(object_name, message: 'not found', status: 404)
    render :json => {"success" => "false", "errors" => "#{object_name.capitalize} #{params[:id]} #{message}"}, status: status
  end


  def record_not_found
    respond_to do |format|
      format.json do
        render json: { errors: {record: ["Not found"]} }, status: 404
      end
    end
  end
end
