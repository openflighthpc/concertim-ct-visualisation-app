class ClusterTypesController < ApplicationController
  load_and_authorize_resource :cluster_type, class: ClusterType

  def index
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config
      use_cache = params[:use_cache] != "false"
      result = SyncAllClusterTypesJob.perform_now(@cloud_service_config, use_cache)
      flash.now.alert = result.error_message unless result.success?
    end
  end
end