class Api::V1::Irv::ChassisController < Api::V1::Irv::BaseController

  def tooltip
    @chassis = Ivy::Chassis.find_by_id(params[:id])
    authorize! :read, @chassis 

    not_found_error('Chassis') if @chassis.nil?
  end

  def update_position
    @chassis = Ivy::Chassis.find_by_id(params[:id])
    authorize! :move, @chassis

    if @chassis.nil?
      not_found_error
      return
    end

    location_params = params.permit(%w[rack_id rack_start_u facing type])
    Ivy::DeviceServices::Move.call(@chassis, location_params, current_user)
    render json: {success: @chassis.save}
  end

  private

  def not_found_error
    render :json => {"error" => "Chassis #{params[:id]} not found"}
  end
end
