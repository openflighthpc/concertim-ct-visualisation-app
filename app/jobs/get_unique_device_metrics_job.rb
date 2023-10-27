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
