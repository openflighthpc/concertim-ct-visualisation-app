class ClusterTypesController < ApplicationController
  load_and_authorize_resource :cluster_type, class: ClusterType

  def index
    @config = Config.first
    if @config
      use_cache = params[:use_cache] != "false"
      result = SyncAllClusterTypesJob.perform_now(@config, use_cache)
      flash.now.alert = result.error_message unless result.success?
    end
  end
end
