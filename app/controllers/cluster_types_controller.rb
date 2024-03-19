class ClusterTypesController < ApplicationController
  load_and_authorize_resource :cluster_type, class: ClusterType

  def index
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config
      use_cache = params[:use_cache] != "false"
      result = SyncAllClusterTypesJob.perform_now(@cloud_service_config, use_cache)
      flash.now.alert = result.error_message unless result.success?
    end
    @cluster_types = @cluster_types.reorder(:order, :id)
    @valid_teams = current_user.teams_where_admin.meets_cluster_credit_requirement
    @unavailable_teams =  current_user.teams.where.not(id: @valid_teams.pluck(:id))
    @all_teams = current_user.teams.reorder(:name)
    @team = Team.find(params[:team_id]) if params[:team_id]
  end
end
