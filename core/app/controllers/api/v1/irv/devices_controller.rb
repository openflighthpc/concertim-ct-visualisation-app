class Api::V1::Irv::DevicesController < Api::V1::Irv::BaseController

  #
  # GET /-/api/v1/irv/devices/:id/tooltip/
  #
  def tooltip
    @device = Ivy::Device.find_by_id(params[:id])
    authorize! :read, @device

    error_for('Device') if @device.nil?
    @device = Api::V1::DevicePresenter.new(@device)
  end

  # 
  # POST /-/api/v1/irv/devices/1/update_slot/
  # 
  # expects param :slot_id
  #
  # XXX Can we remove this???
  def update_slot
    @device     = Ivy::Device.find(params[:id])
    new_slot    = Ivy::Slot.find(params[:slot_id])
    authorize! :move, @device

    begin
      @device = Ivy::DeviceServices::MoveBlade.call(@device, new_slot)
      render :json => { success: true }
    rescue StandardError => e
      error(e.message) and return
    end

  end

  def request_status_change
    @device = Ivy::Device.find(params[:id])
    authorize! :update, @device

    @config = Fleece::Config.last
    if @config.nil?
      render json: { success: false, errors: ["No cloud configuration has been set. Please contact an admin"] }, status: 403
      return
    end

    unless current_user.project_id || current_user.root?
      render json: {
        success: false, errors: ["You do not yet have a project id. This will be added automatically shortly"]
      }, status: 403
      return
    end

    action = params["task"] # action is already used as a param by rails
    unless @device.valid_action?(action)
      render json: { success: false, errors: ["cannot perform action '#{action}' on this device"]}, status: 400
      return
    end

    result = Ivy::RequestStatusChangeJob.perform_now(@device, "devices", action, @config, current_user)

    if result.success?
      render json: { success: true }
    else
      render json: { success: false, errors: [result.error_message] }, status: 400
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
