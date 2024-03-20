class Api::V1::NodesController < Api::V1::ApplicationController

  # create a single node based on a simple chassis template
  def create
    authorize! :create, Device
    result = NodeServices::Create.call(
      find_template,
      location_params.to_h,
      device_params.to_h,
      details_params.to_h,
      current_user,
    )
    if result.success?
      device = result.chassis.device
      @device = Api::V1::DevicePresenter.new(device)
      @include_full_template_details = true
      render template: 'api/v1/devices/show'
    else
      render json: result.failed_record.errors.details, status: :unprocessable_entity
    end
  end

  private

  def find_template
    template_id = params.require(:template_id)
    Template.find(template_id)
  end

  def device_params
    permitted_params.except(:location, :template_id, :details)
  end

  def location_params
    permitted_params.fetch(:location, {}).tap do |h|
      h.permit! if h.empty?
    end
  end

  def details_params
    permitted_params.fetch(:details, {})
  end

  PERMITTED_PARAMS = [
    "name", "description", "status", "cost", "location" => %w[rack_id start_u facing]
  ] << {metadata: {}, details: {}}

  def permitted_params
    params.require(:device).permit(*PERMITTED_PARAMS)
  end
end
