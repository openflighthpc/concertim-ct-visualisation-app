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

class Api::V1::DataSourceMapsController < Api::V1::ApplicationController
  load_and_authorize_resource :data_source_map, class: DataSourceMap

  # Returns a data source map in a format that is suitable for use by the
  # metric reporting daemon.
  def index
    body = { }
    @data_source_maps.each do |dsm|
      g = dsm.map_to_grid
      c = dsm.map_to_cluster
      h = dsm.map_to_host
      next if h.nil?
      body[g] ||= {}
      body[g][c] ||= {}
      body[g][c][h] = dsm.device_id.to_s
    end

    render json: body
  end
end
