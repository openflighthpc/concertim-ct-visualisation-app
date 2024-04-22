class StatisticsController < ApplicationController
  def index
    authorize! :read, :statistics
    @concertim_stats = StatisticsServices::Summary.call
    @cloud_stats = {}
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config
      cloud_stats = GetCloudStatsJob.perform_now(@cloud_service_config)
      if cloud_stats.success?
        @cloud_stats = {totals: cloud_stats.stats}
      else
        flash[:alert] = cloud_stats.error_message
      end
    else
      flash[:alert] = "Unable to retrieve cloud stats - cloud configuration not set"
    end
  end
end
