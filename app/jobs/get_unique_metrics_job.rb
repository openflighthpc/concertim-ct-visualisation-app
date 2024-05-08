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

require 'faraday'

class GetUniqueMetricsJob < ApplicationJob
  queue_as :default

  def perform(**options)
    runner = Runner.new(
      cloud_service_config: nil,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    MetricType = Struct.new(:name, :id, :nature, :units, :min, :max, keyword_init: true)

    attr_reader :metrics, :status_code

    def initialize(success, metrics, error_message, status_code=nil)
      @success = !!success
      @metrics = parse_metrics(metrics)
      @error_message = error_message
      @status_code = status_code
    end

    def success?
      @success
    end

    def error_message
      success? ? nil : @error_message
    end

    private

    def parse_metrics(body)
      metric_types = body.map do |metric|
        MetricType.new(
          id: metric["id"],
          name: metric["name"],
          units: metric["units"].nil? ? nil : metric["units"].force_encoding('utf-8'),
          nature: metric["nature"],
          min: metric["min"],
          max: metric["max"],
        )
      end.sort_by(&:name)
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def call
      response = connection.get(path)
      unless response.success?
        return Result.new(false, [], "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      return Result.new(true, response.body, "")

    rescue Faraday::Error
      status_code = $!.response[:status] rescue 0
      Result.new(false, [], "#{error_description}: #{$!.message}", status_code)
    rescue TypeError
      Result.new(false, [], "Parsing unique metrics failed: #{$!.message}", 0)
    end

    private

    def url
      Rails.application.config.metric_daemon_url
    end

    def path
      "/metrics/unique"
    end

    def error_description
      "Unable to fetch unique metrics"
    end
  end
end
