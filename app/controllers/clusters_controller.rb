class ClustersController < ApplicationController
  def new
    authorize! :create, Cluster
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config.nil?
      flash[:alert] = "Unable to get latest cluster type details: cloud environment config not set"
      redirect_to root_path
      return
    end

    @cluster_type = ClusterType.find_by_foreign_id!(params[:cluster_type_foreign_id])
    use_cache = params[:use_cache] != "false"
    result = SyncIndividualClusterTypeJob.perform_now(@cloud_service_config, @cluster_type, use_cache)
    unless result.success?
      flash[:alert] = "#{result.error_message} - please contact an admin"
      redirect_to cluster_types_path(use_cache: false)
      return
    end
    set_cloud_assets
    @cluster = Cluster.new(cluster_type: @cluster_type)
  end

  def create
    @cloud_service_config = CloudServiceConfig.first
    @cluster_type = ClusterType.find_by_foreign_id!(params[:cluster_type_foreign_id])
    @team = Team.find(permitted_params[:team_id])
    @cluster = Cluster.new(
      cluster_type: @cluster_type, team: @team, name: permitted_params[:name], cluster_params: permitted_params[:cluster_params]
    )

    authorize! :create, @cluster

    if @cloud_service_config.nil?
      flash.now.alert = "Unable to send cluster configuration: cloud environment config not set. Please contact an admin"
      render action: :new
      return
    end

    unless @team.project_id
      flash.now.alert = "Unable to send cluster configuration: selected team does not yet have a project id. " \
                        "This will be added automatically shortly."
      render action: :new
      return
    end

    if !@cluster.valid?
      set_cloud_assets
      render action: :new
      return
    end

    result = CreateClusterJob.perform_now(@cluster, @cloud_service_config, current_user)

    if result.success?
      flash[:success] = "Cluster configuration sent"
      redirect_to interactive_rack_views_path
    elsif result.status_code == 400
      if result.non_field_error?
        flash.now.alert = "Unable to launch cluster: #{result.error_message}"
      end
      set_cloud_assets
      render action: :new
    else
      flash.now.alert = "Unable to send cluster configuration: #{result.error_message}. Please contact an admin"
      set_cloud_assets
      render action: :new
    end
  end

  private

  def permitted_params
    params.require(:cluster).permit(:name, :team_id, cluster_params: @cluster_type.fields.keys)
  end

  def set_cloud_assets
    result = GetCloudAssetsJob.perform_now(@cloud_service_config, current_user)
    if result.success?
      @cloud_assets = result.assets
    else
      @cloud_assets = {}
      Rails.logger.info("Unable to retrieve cloud assets. Rendering degraded cluster form")
    end
  end
end
