class Api::V1::MetricsController < Api::V1::ApplicationController
  MetricType = Struct.new(:name, :id, :units, :min, :max, keyword_init: true)

  def structure
    # XXX Add authorization!  :index metrics/devices/chassis?  Or something
    # else.
    result = GetUniqueMetricsJob.perform_now
    if result.success?
      @definitions = parse_metric_definitions(result)
    else
      render json: {success: false, errors: result.error_message}, status: 502
    end
  end

  private

  def parse_metric_definitions(result)
    metric_types = result.metrics.map do |metric|
      next if metric["nature"] != 'volatile'
      units = metric["units"].nil? ? nil : metric["units"].force_encoding('utf-8')
      mt = MetricType.new(
        id: metric["id"],
        name: metric["name"],
        units: metric["units"] || "",
        min: metric["min"],
        max: metric["max"],
      )
    end
    metric_types
      .compact
      .sort { |a, b| a.id <=> b.id }
  end
end
