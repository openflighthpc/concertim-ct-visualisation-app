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

    start_time = nil
    end_time = nil

    if params[:timeframe] == "range"
      start_time = Date.parse(params[:start_date]).beginning_of_day
      end_time = Date.parse(params[:end_date]).end_of_day
    end

    result = GetHistoricMetricValuesJob.perform_now(metric_name: params[:id], device_id: params[:device_id],
                                                    timeframe: params[:timeframe], start_time: start_time,
                                                    end_time: end_time)

    if result.success?
      render json: result.metric_values.any?(&:value) ? result.metric_values.to_json : []
    elsif result.status_code == 404
      render json: []
    else
      render json: {success: false, errors: result.error_message}, status: 502
    end
  end
end
