class Api::V1::Metrics::MetricsController < Api::V1::Metrics::BaseController

  def structure
    @definitions, @minmaxes = Meca::Metric::Definition.new.metric_definitions
  end
  
end
