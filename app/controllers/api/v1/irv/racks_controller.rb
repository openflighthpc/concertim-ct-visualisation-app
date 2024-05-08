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

class Api::V1::Irv::RacksController < Api::V1::Irv::BaseController

  def index
    authorize! :index, HwRack

    render json: Irv::HwRackServices::Index.call(current_user, params[:rack_ids], params[:slow])
  end

  def modified
    authorize! :index, HwRack
    rack_ids = Array(params[:rack_ids]).collect(&:to_i)
    timestamp = params[:modified_timestamp]
    suppressAdditions = params[:suppress_additions]

    accessible_racks = HwRack.accessible_by(current_ability)
    filtered_racks = accessible_racks.where(id: rack_ids)

    @added = suppressAdditions == "true" ? [] : accessible_racks.excluding_ids(rack_ids)
    @modified = filtered_racks.modified_after(timestamp)
    @deleted = rack_ids - filtered_racks.pluck(:id)
  end

  def request_status_change
    @rack = HwRack.find(params[:id])
    authorize! :update, @rack

    @cloud_service_config = CloudServiceConfig.last
    if @cloud_service_config.nil?
      render json: { success: false, errors: ["No cloud configuration has been set. Please contact an admin"] }, status: 403
      return
    end

    action = params["task"] # action is already used as a param by rails
    unless @rack.valid_action?(action)
      render json: { success: false, errors: ["cannot perform action '#{action}' on this rack"]}, status: 400
      return
    end

    result = RequestStatusChangeJob.perform_now(@rack, "racks", action, @cloud_service_config, current_user)

    if result.success?
      render json: { success: true }
    else
      render json: { success: false, errors: [result.error_message] }, status: 400
    end
  end
end
