class Api::V1::Irv::MetricsController < Api::V1::Irv::BaseController
  MetricValue = Struct.new(:id, :value, keyword_init: true)
  before_action :check_params, :only=>[:index, :show]

  def show
    # XXX Add authorization!  :index metrics/devices/chassis?  Or something
    # else.  Filter device ids according to which can be read?
    device_ids  = params.delete(:device_ids)
    device_ids.map! {|id| Integer(id) rescue id } if device_ids
    @metric  = OpenStruct.new(:name => params[:id])
    result = GetValuesForDevicesWithMetricJob.perform_now(metric_name: @metric.name)
    if result.success?
      @devices = result.metric_values
        .map { |mv| MetricValue.new(id: mv["id"].to_i, value: mv["value"]) }
        .select { |mv| device_ids.nil? || device_ids.include?(mv.id) }
    else
      render json: {success: false, errors: result.error_message}, status: 502
    end
  end


  private

  def check_params
    if params[:id].nil? || params[:id].empty?
      error_for('Metric')
    end
  end

end
