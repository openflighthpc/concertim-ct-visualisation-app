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

class Api::V1::TeamsController < Api::V1::ApplicationController
  load_and_authorize_resource :team

  def index
    @teams = @teams.map { |team| Api::V1::TeamPresenter.new(team) }
  end

  def show
    @team = Api::V1::TeamPresenter.new(@team)
    render
  end

  def update
    if @team.update(team_params)
      @team = Api::V1::TeamPresenter.new(@team)
      render action: :show
    else
      render json: @team.errors.as_json, status: :unprocessable_entity
    end
  end

  def destroy
    if !@team.racks.empty? && !ActiveModel::Type::Boolean.new.cast(params[:recurse])
      error = {status: "422", title: "Unprocessable Content", description: "Cannot delete team as they have active racks"}
      render json: {errors: [error]}, status: :unprocessable_entity
    elsif TeamServices::Delete.call(@team)
      render json: {}, status: :ok
    else
      render json: @team.errors.as_json, status: :unprocessable_entity
    end
  end

  private

  def team_params
    permitted_params =
      if current_user.root?
        [:project_id, :cost, :credits, :billing_acct_id, :billing_period_start, :billing_period_end]
      else
        []
      end
    params.require(:team).permit(*permitted_params)
  end
end
