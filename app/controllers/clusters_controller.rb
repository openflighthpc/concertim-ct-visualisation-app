#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

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
    @team = current_user.teams.find(params[:team_id])
    use_cache = params[:use_cache] != "false"
    result = SyncIndividualClusterTypeJob.perform_now(@cloud_service_config, @cluster_type, use_cache)
    unless result.success?
      flash[:alert] = "#{result.error_message} - please contact an admin"
      redirect_to cluster_types_path(use_cache: false)
      return
    end
    set_cloud_assets
    @cluster = Cluster.new(cluster_type: @cluster_type, team: @team)
  end

  def create
    @cloud_service_config = CloudServiceConfig.first
    @cluster_type = ClusterType.find_by_foreign_id!(params[:cluster_type_foreign_id])
    @team = Team.find(permitted_params[:team_id])
    selections = (permitted_params[:selections] || {}).transform_values { |v| ActiveModel::Type::Boolean.new.cast(v) }.to_h
    @cluster = Cluster.new(
      cluster_type: @cluster_type,
      name: permitted_params[:name],
      cluster_params: permitted_params[:cluster_params],
      selections: selections,
      team: @team
    )

    authorize! :create, @cluster

    if @cloud_service_config.nil?
      flash.now.alert = "Unable to send cluster configuration: cloud environment config not set. Please contact an admin"
      render action: :new
      return
    end

    unless @team.project_id
      flash.now.alert = "Unable to send cluster configuration: your team does not yet have a project id. " \
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
    valid_selections = @cluster_type.field_groups
      .select { |group| group["optional"].present? }
      .map { |group| group["optional"]["name"] }
    params.require(:cluster).permit(:name, :team_id, cluster_params: @cluster_type.fields.keys, selections: valid_selections).tap do |h|
      if !h.key?(:name) && h[:cluster_params].key?(Cluster::NAME_FIELD.to_sym)
        h[:name] = h[:cluster_params][Cluster::NAME_FIELD.to_sym]
      end
    end
  end

  def set_cloud_assets
    result = GetCloudAssetsJob.perform_now(@cloud_service_config, current_user, @team)
    if result.success?
      @cloud_assets = result.assets
    else
      @cloud_assets = {}
      Rails.logger.info("Unable to retrieve cloud assets. Rendering degraded cluster form")
    end
  end
end
