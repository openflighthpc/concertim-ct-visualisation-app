class Api::V1::DevicesController < Api::V1::ApplicationController
  def index
    @devices = Ivy::Device.occupying_rack_u.map {|d| Api::V1::DevicePresenter.new(d) }
    render
  end

  def show
    # XXX load_and_authorize_resource instead.
    @device = Api::V1::DevicePresenter.new(Ivy::Device.find(params[:id]))
    render
  end

  def update
    # XXX Replace with load_and_authorize_resource
    device = Ivy::Device.find(params[:id])
    device, chassis = Ivy::DeviceServices::Update.call(device, device_params.to_h, chassis_params.to_h)

    if device.valid? && chassis.valid? 
      @device = Api::V1::DevicePresenter.new(device)
      render action: :show
    else
      failure_response(!device.valid? ? device : chassis)
    end
  end

  #
  # DELETE /devices/1
  # 
  def destroy
    # XXX Replace with load_and_authorize_resource
    device = Ivy::Device.find(params[:id])

    if Ivy::DeviceServices::Destroy.call(device)
      render json: {}, status: :ok
    else
      render json: device.errors.details, status: :unprocessable_entity
    end
  end

  private

  def device_params
    permitted_params.except(:location)
  end

  def chassis_params
    permitted_params.fetch(:location, {}).tap do |h|
      h[:rack_start_u] = h.delete(:start_u) if h.key?(:start_u)
    end
  end

  PERMITTED_PARAMS = ["name", "description", "location" => %w[rack_id start_u facing]]
  def permitted_params
    params.require(:device).permit(*PERMITTED_PARAMS)
  end
end
