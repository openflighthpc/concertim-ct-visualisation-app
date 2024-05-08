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

class Api::V1::Irv::MetricsController < Api::V1::Irv::BaseController
  before_action :check_params, :only=>[:index, :show]

  def show
    # XXX Add authorization!  :index metrics/devices/chassis?  Or something
    # else.  Filter device ids according to which can be read?
    device_ids  = params.delete(:device_ids)
    @metric  = OpenStruct.new(:name => params[:id])
    result = GetValuesForDevicesWithMetricJob.perform_now(metric_name: @metric.name)
    if result.success?
      @devices = result.metric_values
        .select { |mv| device_ids.nil? || device_ids.include?(mv.id) }
    else
      render json: {success: false, errors: result.error_message}, status: 502
    end
  end


  private

  def check_params
    if params[:id].nil? || params[:id].empty?
      error_for('Metric')
    end
  end

end
