class Api::V1::NodesController < Api::V1::ApplicationController

  # create a single node based on a simple chassis template
  def create
    authorize! :create, Ivy::Device
    result = Ivy::TemplatePersister.new(
      find_template,
      chassis_params.to_h,
      device_params.to_h,
      current_user,
    ).call
    if result.success?
      device = result.chassis.slots.reload.first.device
      @device = Api::V1::DevicePresenter.new(device)
      render template: 'api/v1/devices/show'
    else
      render json: result.failed_record.errors.details, status: :unprocessable_entity
    end
  end

  private

  def find_template
    template_id = params.require(:template_id)
    Ivy::Template.find(template_id)
  end

  def device_params
    permitted_params.except(:location, :template_id)
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
