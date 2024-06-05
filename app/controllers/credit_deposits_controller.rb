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

class CreditDepositsController < ApplicationController
  include ControllerConcerns::ResourceTable
  before_action :set_team, except: [:edit, :update, :destroy]
  load_and_authorize_resource :credit_deposit, only: [:edit, :update, :destroy]

  def new
    @credit_deposit = CreditDeposit.new(team: @team, amount: 1)
    authorize! :create, @credit_deposit
    unless @credit_deposit.valid?
      flash[:alert] = "Unable to add credits: #{@credit_deposit.errors.full_messages.join("; ")}"
      redirect_to teams_path
    end
  end

  def edit
  end

  def create
    @credit_deposit = CreditDeposit.new(team: @team, amount: credit_deposit_params[:amount])
    authorize! :create, @credit_deposit

    unless @credit_deposit.valid?
      flash.now[:alert] = "Unable to add credits: #{@credit_deposit.errors.full_messages.join("; ")}"
      render :new
      return
    end

    if @credit_deposit.save
      flash[:success] = "Credit deposit added for #{@team.name}."
      redirect_to team_credit_deposits_path(team_id: @team.id)
    else
      flash.now[:alert] = "Unable to add credits: #{@credit_deposit.errors.full_messages.join("; ")}"
      render :new
    end
  end

  def index
    authorize! :read, CreditDeposit.new(team: @team)
    @deposits = resource_table_collection(@team.credit_deposits)
  end

  def update
    if @credit_deposit.update(credit_deposit_params)
      flash[:info] = "Successfully updated deposit"
      redirect_to team_credit_deposits_path(team_id: @credit_deposit.team_id)
    else
      flash[:alert] = "Unable to update deposit: #{@credit_deposit.errors.full_messages.join("; ")}"
      render action: :edit
    end
  end

  def destroy
    if @credit_deposit.destroy
      flash[:info] = "Credit deposit destroyed"
    else
      flash[:alert] = "Unable to delete deposit: #{@credit_deposit.errors.full_messages.join("; ")}"
    end
    redirect_to team_credit_deposits_path(team_id: @credit_deposit.team_id)
  end

  private

  def set_team
    @team = Team.find(params[:team_id])
  end

  PERMITTED_PARAMS = %w[amount date]
  def credit_deposit_params
    params.require(:credit_deposit).permit(*PERMITTED_PARAMS)
  end
end
