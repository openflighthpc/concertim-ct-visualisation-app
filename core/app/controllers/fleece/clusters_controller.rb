class Fleece::ClustersController < ApplicationController
  def new
    authorize! :create, Fleece::Cluster
    @config = Fleece::Config.first
    if @config.nil?
      flash[:alert] = "Unable to get latest cluster type details: cloud environment config not set"
      redirect_to root_path
      return
    end

    @cluster_type = Fleece::ClusterType.find_by_foreign_id!(params[:cluster_type_foreign_id])
    use_cache = params[:use_cache] != "false"
    result = Fleece::SyncIndividualClusterTypeJob.perform_now(@config, @cluster_type, use_cache)
    unless result.success?
      flash[:alert] = "#{result.error_message} - please contact an admin"
      redirect_to fleece_cluster_types_path(use_cache: false)
      return
    end
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
      flash.now.alert = "Unable to send cluster configuration: cloud environment config not set. Please contact an admin"
      render action: :new
      return
    end

    unless current_user.project_id
      flash.now.alert = "Unable to send cluster configuration: you do not yet have a project id. " \
                        "This will be added automatically shortly."
      render action: :new
      return
    end

    if !@cluster.valid?
      render action: :new
      return
    end

    result = Fleece::CreateClusterJob.perform_now(@cluster, @config, current_user)

    if result.success?
      flash[:success] = "Cluster configuration sent"
      redirect_to ivy_engine.irv_path
    elsif result.status_code == 400
      if result.non_field_error?
        flash.now.alert = "Unable to launch cluster: #{result.error_message}"
      end
      render action: :new
    else
      flash.now.alert = "Unable to send cluster configuration: #{result.error_message}. Please contact an admin"
      render action: :new
    end
  end

  private

  def permitted_params
    params.require(:fleece_cluster).permit(:name, cluster_params: @cluster_type.fields.keys)
  end
end
