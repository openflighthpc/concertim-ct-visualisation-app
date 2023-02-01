class Api::V1::Irv::ChassisController < Api::V1::Irv::BaseController

  def tooltip
    @chassis = Ivy::Chassis.find_by_id(params[:id])
    # authorize! :read, @chassis 

    error_for('Chassis') if @chassis.nil?
  end

end
