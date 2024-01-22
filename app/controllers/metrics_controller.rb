class MetricsController < ApplicationController
  def index
    @device = Device.find(params[:device_id])
    authorize! :read, @device
    result = GetUniqueDeviceMetricsJob.perform_now(device_id: params[:device_id])

    if result.success?
      @metrics = result.metrics.select { |metric| metric.nature != "string_and_time" }
    elsif result.status_code == 404
      @metrics = []
    else
      flash.now[:alert] = "Unable to retrieve device metrics: #{result.error_message}"
      @metrics = []
    end
  end
end
