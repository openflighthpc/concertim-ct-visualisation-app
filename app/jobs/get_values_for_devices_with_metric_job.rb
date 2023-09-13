require 'faraday'

class GetValuesForDevicesWithMetricJob < ApplicationJob
  queue_as :default

  def perform(metric_name:, **kwargs)
    runner = Runner.new(
      cloud_service_config: nil,
      metric_name: metric_name,
      logger: logger,
      **kwargs
    )
    runner.call
  end

  class Result
    attr_reader :metric_values, :status_code

    def initialize(success, metric_values, error_message, status_code=nil)
      @success = !!success
      @metric_values = metric_values
      @error_message = error_message
      @status_code = status_code
    end

    def success?
      @success
    end

    def error_message
      success? ? nil : @error_message
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(metric_name:, **kwargs)
      @metric_name = metric_name
      super(**kwargs)
    end

    def call
      response = connection.get(path)
      unless response.success?
        return Result.new(false, [], "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      return Result.new(true, response.body, "")

    rescue Faraday::Error
      status_code = $!.response[:status] rescue 0
      Result.new(false, [], "#{error_description}: #{$!.message}", status_code)
    end

    private

    def url
      "http://localhost:3000"
    end

    def path
      "/metrics/#{ERB::Util.url_encode(@metric_name)}/values"
    end

    def error_description
      "Unable to fetch metric values"
    end
  end
end
