class Api::V1::Irv::DevicesController < Api::V1::Irv::BaseController

  #
  # GET /-/api/v1/irv/devices/:id/tooltip/
  #
  def tooltip
    @device = Ivy::Device.find_by_id(params[:id])

    error_for('Device') if @device.nil?
  end

  # 
  # POST /-/api/v1/irv/devices/1/update_slot/
  # 
  # expects param :slot_id
  #
  def update_slot
    @device     = Ivy::Device.find(params[:id])
    new_slot    = Ivy::Slot.find(params[:slot_id])

    begin
      @device = Ivy::DeviceServices::MoveBlade.call(@device, new_slot)
      render :json => { success: true }
    rescue StandardError => e
      error(e.message) and return
    end

  end

  private

  #
  # error
  #
  def error(message = "Device not found")
    render :json => { "error" => message }
  end

end
