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

class CloudServiceConfigsController < ApplicationController
  before_action :load_config
  authorize_resource :cloud_service_config

  def show
    if @cloud_service_config.nil? || !@cloud_service_config.persisted?
      redirect_to new_cloud_service_config_path
    end
  end

  def new
    redirect_to edit_cloud_service_config_path if @cloud_service_config.persisted?
  end

  def create
    if @cloud_service_config.update(config_params)
      flash[:success] = "Cloud environment config created"
      redirect_to cloud_service_config_path
      CloudServiceConfigCreatedJob.perform_later(@cloud_service_config)
    else
      render action: :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to new_cloud_service_config_path if @cloud_service_config.nil? || !@cloud_service_config.persisted?
  end

  def update
    if @cloud_service_config.update(config_params)
      flash[:success] = "Cloud environment config updated"
      redirect_to cloud_service_config_path
    else
      render action: :edit, status: :unprocessable_entity
    end
  end

  private

  PERMITTED_PARAMS = %w[admin_user_id admin_foreign_password admin_project_id internal_auth_url user_handler_base_url cluster_builder_base_url]
  def config_params
    params.require(:cloud_service_config).permit(*PERMITTED_PARAMS)
  end

  def load_config
    @cloud_service_config = CloudServiceConfig.first

    if params[:action] == 'new'
      @cloud_service_config ||= CloudServiceConfig.new
    end
    if params[:action] == 'create'
      raise "Only a single config is supported" unless @cloud_service_config.nil?
      @cloud_service_config = CloudServiceConfig.new
    end
  end
end
