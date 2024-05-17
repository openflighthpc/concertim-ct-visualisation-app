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

class Api::V1::DevicesController < Api::V1::ApplicationController
  load_and_authorize_resource :device, :class => Device

  def index
    @devices = @devices.occupying_rack_u.map {|d| Api::V1::DevicePresenter.new(d) }
    render
  end

  def show
    @device = Api::V1::DevicePresenter.new(@device)
    @include_full_template_details = true
    render
  end

  def update
    @device, chassis, location = DeviceServices::Update.call(
      @device,
      device_params.to_h,
      location_params.to_h,
      details_params.to_h,
      current_user
    )

    if @device.valid? && chassis.valid? && location.valid?
      @device = Api::V1::DevicePresenter.new(@device)
      @include_full_template_details = true
      render action: :show
    else
      failed_object = [@device, location, chassis].detect { |o| !o.valid? }
      render json: {errors: failed_object.errors.as_json}, status: :unprocessable_entity
    end
  end

  #
  # DELETE /devices/1
  # 
  def destroy
    if DeviceServices::Destroy.call(@device)
      render json: {}, status: :ok
    else
      render json: @device.errors.details, status: :unprocessable_entity
    end
  end

  private

  def device_params
    permitted_params.except(
      :location, :details, :public_ips, :private_ips, :ssh_key, :login_user,
      :volume_details
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
        return legacy_params
      end
    end
  end

  PERMITTED_PARAMS = [
    "name", "type", "description", "status", "cost", 
    "public_ips", "private_ips", "ssh_key", "login_user",
    "location" => %w[rack_id start_u facing]
  ] << {metadata: {}, details: {}, volume_details: {}}
  def permitted_params
    params.require(:device).permit(*PERMITTED_PARAMS)
  end
end
