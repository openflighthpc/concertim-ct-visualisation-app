class Fleece::ClusterTypesController < ApplicationController
  load_and_authorize_resource :cluster_type, class: Fleece::ClusterType

  def index
    @config = Fleece::Config.first
    @result = Fleece::GetLatestClusterTypesJob.perform_now(@config) if @config
  end
end
