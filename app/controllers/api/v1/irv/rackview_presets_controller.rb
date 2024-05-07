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

class Api::V1::Irv::RackviewPresetsController < Api::V1::Irv::BaseController

  AUTH_FAILURE_MESSAGE = "You are not the owner of this preset. You can make your own version by loading a preset and re-saving."

  def index
    authorize! :index, RackviewPreset
    @user = current_user
    @presets = RackviewPreset.accessible_by(current_ability)
  end

  # Example JSON request.
  #   {
  #     "preset": {
  #       "values": {
  #         "metricPollRate": "60000",
  #         "showChart": true,
  #         "gradientLBCMetric": false,
  #         "scaleMetrics": true,
  #         "viewMode": "Images and bars",
  #         "face": "both",
  #         "metricLevel": "devices",
  #         "graphOrder": "descending",
  #         "filters": {},
  #         "selectedMetric": "Metric not valid",
  #         "invertedColours": false
  #       },
  #       "name": "F&B",
  #       "default": false
  #     }
  #   }
  def create
    preset = RackviewPreset.new(permitted_params.merge(user_id: current_user.id))
    if cannot? :create, preset
      return failure_response(preset, AUTH_FAILURE_MESSAGE)
    end

    preset.save ? success_response(preset) : failure_response(preset)
  end

  # Example JS request to create a new preset
  #
  # var myRequest = new Request({
  #   url: '/api/irv/rackview_presets/26',
  #   method: 'post'
  # }); 
  #
  # var x=myRequest.post({'preset[name]':'new_name'})
  #
  def update
    preset =
      begin
        RackviewPreset.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        return error_for('preset')
      end
    if cannot? :manage, preset
      return failure_response(preset, AUTH_FAILURE_MESSAGE)
    end

    preset.update(permitted_params)
    preset.save ? success_response(preset) : failure_response(preset)
  end

  # Example JS request to delete a preset
  #
  # var myRequest = new Request({
  #   url: '/api/irv/rackview_presets/23',
  #   method: 'post'
  # });
  #
  # var x=myRequest.delete()
  # 
  def destroy
    preset =
      begin
        RackviewPreset.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        error_for('preset')
      end
    if cannot? :manage, preset
      return failure_response(preset, AUTH_FAILURE_MESSAGE)
    end

    preset.destroy ? success_response(preset) : failure_response(preset)
  end

  private

  PERMITTED_PARAMS = ['name', 'default', 'user_id', { values: {} } ]
  def permitted_params
    params.require(:preset).permit(*PERMITTED_PARAMS)
  end
end
