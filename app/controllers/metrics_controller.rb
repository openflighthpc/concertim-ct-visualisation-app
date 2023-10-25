class MetricsController < ApplicationController
  def index
    @device = Device.find(params[:device_id])
    authorize! :read, @device
    result = GetUniqueDeviceMetricsJob.perform_now(device_id: params[:device_id])

    if result.success?
      @metrics = result.metrics.select { |metric| metric.nature == "volatile" }
    elsif result.status_code == 404
      @metrics = []
    else
      flash[:alert] = "Unable to check device metrics: #{result.error_message}"
      redirect_to interactive_rack_views_path
    end
  end
end
