require 'faraday'

class GetHistoricMetricValuesJob < ApplicationJob
  queue_as :default

  def perform(metric_name:, device_id:, timeframe:, start_time:, end_time:, **kwargs)
    runner = Runner.new(
      cloud_service_config: nil,
      metric_name: metric_name,
      device_id: device_id,
      timeframe: timeframe,
      start_time: start_time,
      end_time: end_time,
      logger: logger,
      **kwargs
    )
    runner.call
  end

  class Result
    MetricValue = Struct.new(:timestamp, :value, keyword_init: true)

    attr_reader :metric_values, :status_code

    def initialize(success, metric_values, error_message, status_code=nil)
      @success = !!success
      @metric_values = parse_metric_values(metric_values)
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

    def parse_metric_values(body)
      body.map do |mv|
        MetricValue.new(timestamp: Time.at(mv["timestamp"]), value: mv["value"])
      end
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(metric_name:, device_id:, timeframe:, start_time:, end_time:,  **kwargs)
      @metric_name = metric_name
      @device_id = device_id
      @timeframe = timeframe
      @start_time = start_time ? start_time.utc.to_i : nil
      @end_time = end_time ? end_time.utc.to_i : nil
      super(**kwargs)
    end

    def call
      response = connection.get(path)
      unless response.success?
        return Result.new(false, [], "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      Result.new(true, response.body, "")

    rescue Faraday::Error
      status_code = $!.response[:status] rescue 0
      Result.new(false, [], "#{error_description}: #{$!.message}", status_code)
    rescue TypeError
      Result.new(false, [], "Parsing metric values failed: #{$!.message}", 0)
    end

    private

    def url
      Rails.application.config.metric_daemon_url
    end

    def path
      if @timeframe == "range"
        "/devices/#{@device_id}/metrics/#{ERB::Util.url_encode(@metric_name)}/historic/#{@start_time}/#{@end_time}"
      else
        "/devices/#{@device_id}/metrics/#{ERB::Util.url_encode(@metric_name)}/historic/last/#{@timeframe}"
      end
    end

    def error_description
      "Unable to fetch metric values"
    end
  end
end
