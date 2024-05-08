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
  def new
    @team = Team.find(params[:team_id])
    @credit_deposit = CreditDeposit.new(team: @team)
    authorize! :create, @credit_deposit
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config.nil?
      flash[:alert] = "Unable to add credits: cloud environment config not set"
      redirect_to teams_path
    elsif !@credit_deposit.valid?
      flash[:alert] = "Unable to add credits: #{@credit_deposit.errors.full_messages.join("; ")}"
      redirect_to teams_path
    end
  end

  def create
    @team = Team.find(params[:team_id])
    @cloud_service_config = CloudServiceConfig.first
    @credit_deposit = CreditDeposit.new(team: @team, amount: credit_deposit_params[:amount])
    authorize! :create, @credit_deposit

    if @cloud_service_config.nil?
      flash[:alert] = "Unable to add credits: cloud environment config not set"
      redirect_to teams_path
      return
    elsif !@credit_deposit.valid?
      flash.now[:alert] = "Unable to add credits: #{@credit_deposit.errors.full_messages.join("; ")}"
      render :new
      return
    end

    result = CreateCreditDepositJob.perform_now(@credit_deposit, @cloud_service_config)
    if result.success?
      flash[:success] = "Credit deposit submitted for #{@team.name}. It may take a few minutes for the team's new balance to be reflected."
      redirect_to teams_path
    else
      flash.now[:alert] = "Unable to submit credit deposit: #{result.error_message}"
      render :new
    end
  end

  private

  PERMITTED_PARAMS = %w[amount]
  def credit_deposit_params
    params.require(:credit_deposit).permit(*PERMITTED_PARAMS)
  end
end
