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
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

class ClusterTypesController < ApplicationController
  include ControllerConcerns::ResourceTable
  load_and_authorize_resource :cluster_type, class: ClusterType
  before_action :get_types, except: [:edit, :update]

  def index
    @cluster_types = @cluster_types.where.not(base_compute_units: nil)
    @valid_teams = current_user.teams_where_admin.select(&:meets_cluster_compute_unit_requirement?)
    @unavailable_teams =  current_user.teams.where.not(id: @valid_teams.pluck(:id))
    @all_teams = current_user.teams.reorder(:name)
    @team = Team.find(params[:team_id]) if params[:team_id]
  end

  def admin_index
    @cluster_types = resource_table_collection(@cluster_types)
  end

  def edit
  end

  def update
    if @cluster_type.update(cluster_type_params)
      flash[:info] = "Successfully updated cluster type compute_units"
      redirect_to admin_cluster_type_index_path
    else
      flash[:alert] = "Unable to update cluster type: #{@cluster_type.errors.full_messages.join("; ")}"
      render action: :edit
    end
  end

  private

  def get_types
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config
      use_cache = params[:use_cache] != "false"
      result = SyncAllClusterTypesJob.perform_now(@cloud_service_config, use_cache)
      flash.now.alert = result.error_message unless result.success?
    end
    @cluster_types = @cluster_types.reorder(:order, :id)
  end

  PERMITTED_PARAMS = %w[base_compute_units]
  def cluster_type_params
    params.require(:cluster_type).permit(*PERMITTED_PARAMS)
  end
end
