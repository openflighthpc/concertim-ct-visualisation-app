class Api::V1::MetricsController < Api::V1::ApplicationController
  def structure
    # XXX Add authorization!  :index metrics/devices/chassis?  Or something
    # else.
    result = GetUniqueMetricsJob.perform_now
    if result.success?
      @definitions = result.metrics
        .filter { |m| m.nature == "volatile" }
        .sort { |a, b| a.id <=> b.id }
    else
      render json: {success: false, errors: result.error_message}, status: 502
    end
  end
end
