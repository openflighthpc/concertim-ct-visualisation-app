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
    attr_reader :metrics, :status_code

    def initialize(success, metrics, error_message, status_code=nil)
      @success = !!success
      @metrics = metrics
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
      "/metrics/unique"
    end

    def error_description
      "Unable to fetch metric definitions"
    end
  end
end
