class Api::V1::Irv::MetricsController < Api::V1::Irv::BaseController

  before_action :check_params, :only=>[:index, :show]

  def show
    # XXX Add authorization!  :index metrics/devices/chassis?  Or something
    # else.  Filter device ids according to which can be read?
    device_ids  = params.delete :device_ids
    device_ids  = JSON.parse(device_ids) if device_ids
    tagged_devices_ids = params.delete :tagged_devices_ids
    tagged_devices_ids = JSON.parse(tagged_devices_ids) if tagged_devices_ids

    metric_definition = Meca::Metric::Definition.new(:device_ids=>device_ids, :tagged_devices_ids=>tagged_devices_ids)

    @metric  = OpenStruct.new(:name => params[:id])
    @devices = metric_definition.values_for_devices_with_metric(@metric.name)
    @chassis = metric_definition.values_for_chassis_with_metric(@metric.name)
  end


  private

  def check_params
    if params[:id].nil? || params[:id].empty?
      error_for('Metric')
    end
  end

end
