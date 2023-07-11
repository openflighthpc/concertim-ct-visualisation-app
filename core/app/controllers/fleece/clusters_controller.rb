class Fleece::ClustersController < ApplicationController
  def new
    authorize! :create, Fleece::Cluster
    @cluster_type = Fleece::ClusterType.find_by_foreign_id!(params[:cluster_type_foreign_id])
    @cluster = Fleece::Cluster.new(cluster_type: @cluster_type)
  end

  def create
    authorize! :create, Fleece::Cluster
    @config = Fleece::Config.first
    @cluster_type = Fleece::ClusterType.find_by_foreign_id!(params[:cluster_type_foreign_id])
    @cluster = Fleece::Cluster.new(
      cluster_type: @cluster_type, name: permitted_params[:name], cluster_params: permitted_params[:cluster_params]
    )

    if @config.nil?
      flash.now.alert = "Unable to send cluster configuration: cloud environment config not set"
      render action: :new
      return
    end

    unless current_user.project_id
      flash.now.alert = "Unable to send cluster configuration: you do not yet have a project id"
      render action: :new
      return
    end

    if !@cluster.valid?
      render action: :new
      return
    end

    result = Fleece::CreateClusterJob.perform_now(@cluster, @config, current_user)

    if result.success?
      flash.now.success = "Cluster configuration sent"
      redirect_to ivy_engine.irv_path
    else
      flash.now.alert = "Unable to send cluster configuration: #{result.error_message}"
      render action: :new
    end
  end

  private

  def permitted_params
    params.require(:fleece_cluster).permit(:name, cluster_params: @cluster_type.fields.keys)
  end
end
