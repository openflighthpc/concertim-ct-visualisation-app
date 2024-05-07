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

require 'faraday'

class GetUniqueDeviceMetricsJob < GetUniqueMetricsJob
  queue_as :default

  def perform(device_id:, **kwargs)
    runner = Runner.new(
      cloud_service_config: nil,
      device_id: device_id,
      logger: logger,
      **kwargs
    )
    runner.call
  end

  class Runner < GetUniqueMetricsJob::Runner
    def initialize(device_id:,  **kwargs)
      @device_id = device_id
      super(**kwargs)
    end

    private

    def path
      "/devices/#{@device_id}/metrics/current"
    end
  end
end
