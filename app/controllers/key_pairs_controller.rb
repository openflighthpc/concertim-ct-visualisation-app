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

class KeyPairsController < ApplicationController
  before_action :set_project_id, except: :new

  def new
    @user = current_user
    @key_pair = KeyPair.new(user: @user)
    authorize! :create, @key_pair
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config.nil?
      flash[:alert] = "Unable to create key-pairs: cloud environment config not set"
      redirect_to root_path
    end
  end

  def index
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config.nil?
       flash[:alert] = "Unable to check key-pairs: cloud environment config not set. Please contact an admin"
       redirect_to edit_user_registration_path
       return
    end

    unless @project_id
      flash[:alert] = "Unable to check key-pairs: you must belong to a team with a project id."
      redirect_to edit_user_registration_path
      return
    end

    result = GetUserKeyPairsJob.perform_now(@cloud_service_config, current_user, @project_id)
    if result.success?
      @key_pairs = result.key_pairs
    else
      flash[:alert] = "Unable to get key-pairs: #{result.error_message}"
      redirect_to edit_user_registration_path
    end
  end

  def create
    @cloud_service_config = CloudServiceConfig.first
    @user = current_user
    public_key = key_pair_params[:public_key].blank? ? nil : key_pair_params[:public_key]
    @key_pair = KeyPair.new(user: @user, name: key_pair_params[:name], key_type: key_pair_params[:key_type],
                                                public_key: public_key)
    authorize! :create, @key_pair

    if @cloud_service_config.nil?
      flash[:alert] = "Unable to send key-pair requests: cloud environment config not set. Please contact an admin"
      redirect_to edit_user_registration_path
      return
    end

    unless @project_id
      flash[:alert] = "Unable to create key-pair: you must belong to a team with a project id."
      redirect_to edit_user_registration_path
      return
    end

    result = CreateKeyPairJob.perform_now(@key_pair, @cloud_service_config, current_user, @project_id)

    if result.success?
      render action: :success
    else
      flash[:alert] = result.error_message
      redirect_to key_pairs_path
    end
  end

  def destroy
    authorize! :destroy, KeyPair.new(user: current_user)
    @cloud_service_config = CloudServiceConfig.first
    @user = current_user
    if @cloud_service_config.nil?
      flash[:alert] = "Unable to send key-pair requests: cloud environment config not set. Please contact an admin"
      redirect_to edit_user_registration_path
      return
    end

    unless @project_id
      flash[:alert] = "Unable to send key-pair deletion request: you must belong to a team with a project id."
      redirect_to edit_user_registration_path
      return
    end

    result = DeleteKeyPairJob.perform_now(params[:name], @cloud_service_config, current_user, @project_id)

    if result.success?
      flash[:success] = "Key-pair '#{params[:name]}' deleted"
    else
      flash[:alert] = result.error_message
    end
    redirect_to key_pairs_path
  end

  private

  PERMITTED_PARAMS = %w[name key_type public_key]
  def key_pair_params
    params.require(:key_pair).permit(*PERMITTED_PARAMS)
  end

  # key pairs are user (not project) specific, but membership of a project is required
  # to view, create and delete them
  def set_project_id
    @project_id = current_user.teams.where.not(project_id: nil).where(deleted_at: nil).first&.project_id
  end
end
