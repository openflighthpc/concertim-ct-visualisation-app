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

class GetCloudStatsJob < ApplicationJob
  queue_as :default

  def perform(cloud_service_config, **options)
    runner = Runner.new(
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    attr_reader :stats

    def initialize(success, stats, error_message)
      @success = !!success
      @stats = stats
      @error_message = error_message
    end

    def success?
      @success
    end

    def error_message
      success? ? nil : @error_message
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner

    def call
      response = connection.get(path)
      unless response.success?
        return Result.new(false, {}, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end
      Result.new(true, format_response(response.body["stats"]), nil)
    rescue Faraday::Error
      Result.new(false, {}, "#{error_description}: #{$!.message}")
    end

    private

    def url
      @cloud_service_config.user_handler_base_url
    end

    def path
      "/statistics"
    end

    def error_description
      "Unable to retrieve cloud statistics"
    end

    def format_response(data)
      {
        "Allocated / Total VCPUs" => "#{data['used_vcpus']} / #{data['total_vcpus']}",
        "Allocated / Total Disk Space" => "#{data['used_disk_space']&.ceil(1)} / #{data['total_disk_space']&.ceil(1)}GB",
        "Allocated / Total RAM" => "#{data['used_ram']&.ceil(1)} / #{data['total_ram']&.ceil(1)}GB",
        "Virtual Machines" => "#{data['running_vms']}"
      }
    end
  end
end
