require 'faraday'

class GetHistoricMetricValuesJob < ApplicationJob
  queue_as :default

  def perform(metric_name:,device_id:, start_date:, end_date:, **kwargs)
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
    def initialize(metric_name:, device_id:, start_date:, end_date:,  **kwargs)
      @metric_name = metric_name
      @device_id = device_id
      @start_time = start_date.beginning_of_day.utc.to_i
      @end_time = end_date.end_of_day.utc.to_i
      super(**kwargs)
    end

    def call
      # mocked_data = [
      #   {"timestamp" => 1696420533, "value" => 12},
      #   {"timestamp" => 1696420548, "value" => 9},
      #   {"timestamp" => 1696420518, "value" => 8},
      #   {"timestamp" => 1696420503, "value" => 10}
      # ]
      # Result.new(true, mocked_data, "")
      response = connection.get(path)
      unless response.success?
        return Result.new(false, [], "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      dataset = group_results(response.body)
      return Result.new(true, dataset, "")

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
      "/device/#{@device_id}/metrics/#{ERB::Util.url_encode(@metric_name)}/historic/#{@start_time}/#{@end_time}"
    end

    def error_description
      "Unable to fetch metric values"
    end

    # We want to show hourly averages
    def group_results(body)
      hourly_averages = {}
      finish = [Time.current.utc.to_i, @end_time].min
      hours_to_cover = ((finish - @start_time) / 3600) + 1
      count = 0
      start = Time.at(@start_time)
      while count < hours_to_cover
        hourly_averages[(start + (3600 * count)).strftime('%y-%m-%d %H:00')] = []
        count += 1
      end

      any_values = false
      body.each do |item|
        next if item["value"].nil?

        any_values = true
        timestamp = Time.at(item["timestamp"])
        hour_key = timestamp.strftime('%y-%m-%d %H:00')
        hourly_averages[hour_key] << item["value"]
      end

      return [] unless any_values

      [].tap do |results|
        hourly_averages.each do |hour_key, values|
          results << { timestamp: hour_key, value: ("%.2f" % (values.sum / values.length.to_f)) }
        end
      end
    end
  end
end
