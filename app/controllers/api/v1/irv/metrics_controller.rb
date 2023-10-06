class Api::V1::Irv::MetricsController < Api::V1::Irv::BaseController
  before_action :check_params, :only=>[:index, :show, :historic]

  def show
    # XXX Add authorization!  :index metrics/devices/chassis?  Or something
    # else.  Filter device ids according to which can be read?
    device_ids  = params.delete(:device_ids)
    device_ids.map! {|id| Integer(id) rescue id } if device_ids
    @metric  = OpenStruct.new(:name => params[:id])
    result = GetValuesForDevicesWithMetricJob.perform_now(metric_name: @metric.name)
    if result.success?
      @devices = result.metric_values
        .select { |mv| device_ids.nil? || device_ids.include?(mv.id) }
    else
      render json: {success: false, errors: result.error_message}, status: 502
    end
  end

  def historic
    result = GetHistoricMetricValuesJob.perform_now(metric_name: params[:id], device_id: params[:device_id],
                                                    start_date: params[:start_date], end_date: [params[:end_date]]
    )
    if result.success?
      # put in suitable chart format
      render json: result.metric_values.to_json
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
