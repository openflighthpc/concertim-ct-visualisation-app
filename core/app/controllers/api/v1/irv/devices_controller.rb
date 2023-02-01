class Api::V1::Irv::DevicesController < Api::V1::Irv::BaseController

  #
  # GET /-/api/v1/irv/devices/:id/tooltip/
  #
  def tooltip
    @device = Ivy::Device.find_by_id(params[:id])

    error_for('Device') if @device.nil?
  end

end
