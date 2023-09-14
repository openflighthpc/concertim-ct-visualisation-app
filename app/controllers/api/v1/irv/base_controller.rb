# For use by the interactive rack view
class Api::V1::Irv::BaseController < Api::V1::ApplicationController

  private

  def success_response(object, message = [])
    render :json => {"success" => "true", "action" => params[:action], "id" => object[:id], "data" => message}
  end

  def failure_response(object)
    # FSR this renders everything as a 200 response.  Not sure what the effects
    # on the IRV of changing that would be.
    render json: {errors: object.errors.as_json}
  end
end
