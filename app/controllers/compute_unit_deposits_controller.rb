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

class ComputeUnitDepositsController < ApplicationController
  include ControllerConcerns::ResourceTable
  before_action :set_team, except: [:edit, :update, :destroy]
  load_and_authorize_resource :compute_unit_deposit, only: [:edit, :update, :destroy]

  def new
    @compute_unit_deposit = ComputeUnitDeposit.new(team: @team, amount: 1)
    authorize! :create, @compute_unit_deposit
    unless @compute_unit_deposit.valid?
      flash[:alert] = "Unable to add compute_units: #{@compute_unit_deposit.errors.full_messages.join("; ")}"
      redirect_to teams_path
    end
  end

  def edit
  end

  def create
    @compute_unit_deposit = ComputeUnitDeposit.new(team: @team, amount: compute_unit_deposit_params[:amount])
    authorize! :create, @compute_unit_deposit

    unless @compute_unit_deposit.valid?
      flash.now[:alert] = "Unable to add compute units: #{@compute_unit_deposit.errors.full_messages.join("; ")}"
      render :new
      return
    end

    if @compute_unit_deposit.save
      flash[:success] = "Compute unit deposit added for #{@team.name}."
      redirect_to team_compute_unit_deposits_path(team_id: @team.id)
    else
      flash.now[:alert] = "Unable to add compute units: #{@compute_unit_deposit.errors.full_messages.join("; ")}"
      render :new
    end
  end

  def index
    authorize! :read, ComputeUnitDeposit.new(team: @team)
    @deposits = resource_table_collection(@team.compute_unit_deposits)
  end

  def update
    if @compute_unit_deposit.update(compute_unit_deposit_params)
      flash[:info] = "Successfully updated deposit"
      redirect_to team_compute_unit_deposits_path(team_id: @compute_unit_deposit.team_id)
    else
      flash[:alert] = "Unable to update deposit: #{@compute_unit_deposit.errors.full_messages.join("; ")}"
      render action: :edit
    end
  end

  def destroy
    if @compute_unit_deposit.destroy
      flash[:info] = "Compute unit deposit destroyed"
    else
      flash[:alert] = "Unable to delete deposit: #{@compute_unit_deposit.errors.full_messages.join("; ")}"
    end
    redirect_to team_compute_unit_deposits_path(team_id: @compute_unit_deposit.team_id)
  end

  private

  def set_team
    @team = Team.find(params[:team_id])
  end

  PERMITTED_PARAMS = %w[amount date]
  def compute_unit_deposit_params
    params.require(:compute_unit_deposit).permit(*PERMITTED_PARAMS)
  end
end
