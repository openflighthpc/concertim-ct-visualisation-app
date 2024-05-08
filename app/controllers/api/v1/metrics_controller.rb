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

class Api::V1::MetricsController < Api::V1::ApplicationController
  def structure
    # XXX Add authorization!  :index metrics/devices/chassis?  Or something
    # else.
    result = GetUniqueMetricsJob.perform_now
    if result.success?
      @definitions = result.metrics
        .filter { |m| m.nature == "volatile" }
        .sort { |a, b| a.id <=> b.id }
    else
      render json: {success: false, errors: result.error_message}, status: 502
    end
  end

  def show
    @device = Device.find_by(id: params[:device_id])
    unless @device
      render json: {success: false, errors: "Device not found"}, status: 404
    end
    authorize! :read, @device

    start_time = nil
    end_time = nil

    if params[:timeframe] == "range"
      start_time = Date.parse(params[:start_date]).beginning_of_day
      end_time = Date.parse(params[:end_date]).end_of_day
    end

    result = GetHistoricMetricValuesJob.perform_now(metric_name: params[:id], device_id: params[:device_id],
                                                    timeframe: params[:timeframe], start_time: start_time,
                                                    end_time: end_time)

    if result.success?
      render json: result.metric_values.any?(&:value) ? result.metric_values.to_json : []
    elsif result.status_code == 404
      render json: []
    else
      render json: {success: false, errors: result.error_message}, status: 502
    end
  end
end
