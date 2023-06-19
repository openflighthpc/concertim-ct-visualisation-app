class Fleece::ClustersController < ApplicationController
  def new
    authorize! :create, Fleece::Cluster
    @cluster_type = Fleece::ClusterType.find(params[:cluster_type_id])
    @cluster = Fleece::Cluster.new(kind: @cluster_type, nodes: @cluster_type.nodes)
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
    @cluster = Fleece::Cluster.new(kind: @cluster_type, **cluster_params)
    if !@cluster.valid?
      render action: :new
      return
    end

    result = Fleece::PostCreateClusterJob.perform_now(@cluster, @config)

    if result.success?
      flash[:success] = "Cluster configuration sent (or at least faked)"
      redirect_to ivy_engine.irv_path
    else
      flash[:alert] = "Unable to send cluster configuration: #{result.error_message}"
      render action: :new
    end
  end

  private

  PERMITTED_PARAMS = %w[name nodes]
  def cluster_params
    params.require(:fleece_cluster).permit(*PERMITTED_PARAMS)
  end
end
