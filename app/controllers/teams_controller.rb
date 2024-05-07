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

class TeamsController < ApplicationController
  include ControllerConcerns::ResourceTable
  load_and_authorize_resource :team, except: :create

  def index
    @teams = resource_table_collection(@teams)
  end

  def usage_limits
    @cloud_service_config = CloudServiceConfig.first
    authorize! :read, @team

    if @cloud_service_config.nil?
      flash[:alert] = "Unable to view team quotas: cloud environment config not set."
      redirect_to teams_path
      return
    end

    if @team.project_id.nil?
      flash[:alert] = "Unable to view team quotas: team does not have a cloud project."
      redirect_to teams_path
      return
    end

    result = GetTeamLimitsJob.perform_now(@cloud_service_config, @team, current_user)
    if result.success?
      @limits = result.limits
    else
      flash[:alert] = result.error_message
      redirect_to teams_path
    end
  end

  def create
    @cloud_service_config = CloudServiceConfig.first
    @team = Team.new(name: team_params[:name])
    authorize! :create, @team

    if @cloud_service_config.nil?
      flash[:alert] = "Unable to create new team: cloud environment config not set."
      redirect_to new_team_path
      return
    end

    if @team.save
      CreateTeamJob.perform_later(@team, @cloud_service_config)
      flash[:success] = "Team created. Project ID and billing account ID should be added automatically."
      redirect_to teams_path
    else
      flash.now[:alert] = "Unable to create team"
      render action: :new
    end
  end

  def update
    if @team.update(team_params)
      flash[:info] = "Successfully updated team"
      redirect_to teams_path
    else
      flash[:alert] = "Unable to update team"
      render action: :edit
    end
  end

  def destroy
    if TeamServices::Delete.call(@team)
      flash[:info] = "Scheduled team for deletion"
    else
      flash[:alert] = "Unable to schedule team for deletion"
    end
    redirect_to teams_path
  end

  private

  PERMITTED_PARAMS = %w[name project_id billing_acct_id]
  def team_params
    params.fetch(:team).permit(*PERMITTED_PARAMS)
  end
end
