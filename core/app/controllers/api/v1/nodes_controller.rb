class Api::V1::NodesController < Api::V1::ApplicationController

  # create a single node based on a simple chassis template
  def create
    res = Ivy::TemplatePersister.persist_one_with_changes(create_params)
    if res[:success]
      device = res[:chassis].slots.reload.first.device
      @device = Api::V1::DevicePresenter.new(device)
      render template: 'api/v1/devices/devices/show'
    else
      failure_response(res[:failed_objs].first)
    end
  end

  private

  def create_params
    # XXX Remove hardcoding here.  What do template mean in the new cloud world?
    template_id = 613
    template = Ivy::Template.find(template_id)
    {
      chassis: chassis_params(template).to_h,
      devices: device_params(template).to_h,
    }

  end

  def device_params(template)
    permitted_params.except(:location).tap do |h|
      h[:type] = template.chassis_type
      h[:template_manufacturer] = template.manufacturer
      h[:template_id] = template.id
    end
  end

  def chassis_params(template)
    permitted_params.fetch(:location, {}).tap do |h|
      h[:rack_start_u] = h.delete(:start_u) if h.key?(:start_u)
      h[:u_height] = template.height
      h[:u_depth] = template.depth
    end
  end

  PERMITTED_PARAMS = ["name", "description", "location" => %w[rack_id start_u facing]]
  def permitted_params
    params.require(:device).permit(*PERMITTED_PARAMS)
  end
end
