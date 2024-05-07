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

class Api::V1::NodesController < Api::V1::ApplicationController

  # create a single node based on a simple chassis template
  def create
    authorize! :create, Device
    result = NodeServices::Create.call(
      find_template,
      location_params.to_h,
      device_params.to_h,
      details_params.to_h,
      current_user,
    )
    if result.success?
      device = result.chassis.device
      @device = Api::V1::DevicePresenter.new(device)
      @include_full_template_details = true
      render template: 'api/v1/devices/show'
    else
      render json: result.failed_record.errors.details, status: :unprocessable_entity
    end
  end

  private

  def find_template
    template_id = params.require(:template_id)
    Template.find(template_id)
  end

  def device_params
    permitted_params.except(:location, :template_id, :details, 
      :public_ips, :private_ips, :ssh_key, :login_user, :volume_details
    )
  end

  def location_params
    permitted_params.fetch(:location, {}).tap do |h|
      h.permit! if h.empty?
    end
  end

  def details_params
    permitted_params.fetch(:details, {}).tap do |details|
      if details.empty?
        legacy_params = permitted_params.slice(
          :public_ips,
          :private_ips,
          :ssh_key,
          :login_user,
          :volume_details
        )
        legacy_params[:type] = 'Device::ComputeDetails'
        return legacy_params
      end
    end
  end

  PERMITTED_PARAMS = [
    "name", "description", "status", "cost", 
    "public_ips", "private_ips", "ssh_key", "login_user",
    "location" => %w[rack_id start_u facing],
  ] << {metadata: {}, details: {}, volume_details: {}}

  def permitted_params
    params.require(:device).permit(*PERMITTED_PARAMS)
  end
end
