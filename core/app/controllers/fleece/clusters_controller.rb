class Fleece::ClustersController < ApplicationController
  def new
    authorize! :create, Fleece::Cluster
    @cluster_type = Fleece::ClusterType.find(params[:cluster_type_id])
    @cluster = Fleece::Cluster.new(cluster_type: @cluster_type)
  end

  def create
    authorize! :create, Fleece::Cluster
    @config = Fleece::Config.first

    if @config.nil?
      flash[:alert] = "Unable to send cluster configuration: cloud environment config not set"
      render action: :new
      return
    end

    @cluster_type = Fleece::ClusterType.find(params[:cluster_type_id])
    @cluster = Fleece::Cluster.new(
      cluster_type: @cluster_type, name: permitted_params[:name], cluster_params: permitted_params[:cluster_params]
    )
    if !@cluster.valid?
      render action: :new
      return
    end

    result = Fleece::CreateClusterJob.perform_now(@cluster, @config, current_user)

    if result.success?
      flash[:success] = "Cluster configuration sent"
      redirect_to ivy_engine.irv_path
    else
      flash[:alert] = "Unable to send cluster configuration: #{result.error_message}"
      render action: :new
    end
  end

  private

  def permitted_params
    params.require(:fleece_cluster).permit(:name, cluster_params: @cluster_type.fields.keys)
  end
end
