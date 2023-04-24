class Api::V1::MetricsController < Api::V1::ApplicationController

  def structure
    # XXX Add authorization!  :index metrics/devices/chassis?  Or something
    # else.  Filter device ids according to which can be read?
    @definitions, @minmaxes = Meca::Metric::Definition.new.metric_definitions
  end
  
end
