class Api::V1::MetricsController < Api::V1::ApplicationController
  def structure
    # XXX Add authorization!  :index metrics/devices/chassis?  Or something
    # else.
    result = GetUniqueMetricsJob.perform_now
    if result.success?
      @definitions = result.metrics
        .filter { |m| m.nature == "volatile" }
        .sort { |a, b| a.id <=> b.id }
    else
      render json: {success: false, errors: result.error_message}, status: 502
    end
  end

  def show
    @device = Device.find_by(id: params[:device_id])
    unless @device
      render json: {success: false, errors: "Device not found"}, status: 404
    end
    authorize! :read, @device

    case params[:timeframe]
    when "hour"
      end_time = Time.current
      start_time = end_time - 60.minutes
    when "day"
      end_time = Time.current
      start_time = end_time - 1.day
    when "range"
      end_time = Date.parse(params[:end_date]).end_of_day
      start_time = Date.parse(params[:start_date]).beginning_of_day
    end

    result = GetHistoricMetricValuesJob.perform_now(metric_name: params[:id], device_id: params[:device_id],
                                                    start_time: start_time, end_time: end_time)

    if result.success?
      render json: result.metric_values.any?(&:value) ? result.metric_values.to_json : []
    elsif result.status_code == 404
      render json: []
    else
      render json: {success: false, errors: result.error_message}, status: 502
    end
  end
end
