class Fleece::ClusterTypesController < ApplicationController
  load_and_authorize_resource :cluster_type, class: Fleece::ClusterType

  def index
    @config = Fleece::Config.first
    if @config
      result = Fleece::SyncLatestClusterTypesJob.perform_now(@config)
      flash.now.alert = result.error_message unless result.success?
    end
  end
end
