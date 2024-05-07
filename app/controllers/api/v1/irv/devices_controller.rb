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

class Api::V1::Irv::DevicesController < Api::V1::Irv::BaseController

  # 
  # POST /-/api/v1/irv/devices/1/update_slot/
  # 
  # expects param :slot_id
  #
  # XXX Can we remove this???
  def update_slot
    @device     = Device.find(params[:id])
    new_slot    = Slot.find(params[:slot_id])
    authorize! :move, @device

    begin
      @device = DeviceServices::MoveBlade.call(@device, new_slot)
      render :json => { success: true }
    rescue StandardError => e
      error(e.message) and return
    end

  end

  def request_status_change
    @device = Device.find(params[:id])
    authorize! :update, @device

    @cloud_service_config = CloudServiceConfig.last
    if @cloud_service_config.nil?
      render json: { success: false, errors: ["No cloud configuration has been set. Please contact an admin"] }, status: 403
      return
    end

    action = params["task"] # action is already used as a param by rails
    unless @device.valid_action?(action)
      render json: { success: false, errors: ["cannot perform action '#{action}' on this device"]}, status: 400
      return
    end

    result = RequestStatusChangeJob.perform_now(@device, "devices", action, @cloud_service_config, current_user)

    if result.success?
      render json: { success: true }
    else
      render json: { success: false, errors: [result.error_message] }, status: 400
    end
  end

  private

  #
  # error
  #
  def error(message = "Device not found")
    render :json => { "error" => message }
  end

end
