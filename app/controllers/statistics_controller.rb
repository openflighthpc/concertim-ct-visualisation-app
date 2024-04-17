class StatisticsController < ApplicationController
  def index
    @concertim_stats = StatisticsServices::Summary.call
    @cloud_stats = {}
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config
      cloud_stats = GetCloudStatsJob.perform_now(@cloud_service_config)
      unless cloud_stats.success?
        flash[:alert] = cloud_stats.error_message
      else
        @cloud_stats = {totals: cloud_stats.stats}
      end
    else
      flash[:alert] = "Unable to retrieve cloud stats - cloud configuration not set"
    end
  end
end
