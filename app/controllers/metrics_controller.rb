class MetricsController < ApplicationController
  def index
    device = Device.find(params[:device_id])
  end
end
