require 'faraday'

class GetHistoricMetricValuesJob < ApplicationJob
  queue_as :default

  def perform(metric_name:,device_id:, start_date:, end_date: Date.current, **kwargs)
    runner = Runner.new(
      cloud_service_config: nil,
      metric_name: metric_name,
      device_id: device_id,
      start_date: start_date,
      end_date: end_date,
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
        MetricValue.new(timestamp: Time.at(mv["timestamp"].to_i), value: mv["value"])
      end
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(metric_name:, device_id:, start_date:, end_date:,  **kwargs)
      @metric_name = metric_name
      @device_id = device_id
      @start_date = start_date
      @end_date = end_date
      super(**kwargs)
    end

    def call
      mocked_data = [
        {"timestamp" => 1696420533, "value" => 12},
        {"timestamp" => 1696420548, "value" => 9},
        {"timestamp" => 1696420518, "value" => 8},
        {"timestamp" => 1696420503, "value" => 10}
      ]
      Result.new(true, mocked_data, "")
    #   response = connection.get(path)
    #   unless response.success?
    #     return Result.new(false, [], "#{error_description}: #{response.reason_phrase || "Unknown error"}")
    #   end
    #
    #   return Result.new(true, response.body, "")
    #
    # rescue Faraday::Error
    #   status_code = $!.response[:status] rescue 0
    #   Result.new(false, [], "#{error_description}: #{$!.message}", status_code)
    # rescue TypeError
    #   Result.new(false, [], "Parsing metric values failed: #{$!.message}", 0)
    end

    private

    def url
      Rails.application.config.metric_daemon_url
    end

    def path
      "/metrics/#{ERB::Util.url_encode(@metric_name)}/values"
    end

    def error_description
      "Unable to fetch metric values"
    end
  end
end
