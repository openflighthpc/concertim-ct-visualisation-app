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
      end
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
