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

    @chassis.update_position(params.permit(%w[rack_id rack_start_u facing type]).to_h)
    @chassis.calculate_rack_end_u
    
    render json: {success: @chassis.save}
  end

  private

  def not_found_error
    render :json => {"error" => "Chassis #{params[:id]} not found"}
  end
end
