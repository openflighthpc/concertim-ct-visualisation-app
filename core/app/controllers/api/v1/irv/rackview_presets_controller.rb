class Api::V1::Irv::RackviewPresetsController < Api::V1::Irv::BaseController

  AUTH_FAILURE_MESSAGE = "You are not the owner of this preset. You can make your own version by loading a preset and re-saving."

  def index
    authorize! :index, Meca::RackviewPreset
    @user = current_user
    @presets = Meca::RackviewPreset.all
  end

  # Example JSON request.
  #   {
  #     "preset": {
  #       "values": {
  #         "metricPollRate": "60000",
  #         "showChart": "true",
  #         "gradientLBCMetric": "false",
  #         "scaleMetrics": "true",
  #         "viewMode": "\"Images and bars\"",
  #         "face": "\"both\"",
  #         "metricLevel": "\"devices\"",
  #         "graphOrder": "\"descending\"",
  #         "filters": "{}",
  #         "selectedMetric": "\"Metric not valid\"",
  #         "selectedGroup": "null",
  #         "invertedColours": "false"
  #       },
  #       "name": "F&B",
  #       "default": "false"
  #     }
  #   }
  def create
    permitted_params.tap do |h|
      h[:user_id] = current_user.id
    end
    preset = Meca::RackviewPreset.new(permitted_params)
    if cannot? :create, preset
      return failure_response(preset, AUTH_FAILURE_MESSAGE)
    end

    preset.save ? success_response(preset) : failure_response(preset)
  end

  # Example JS request to create a new preset
  #
  # var myRequest = new Request({
  #   url: '/--/api/irv/rackview_presets/26',
  #   method: 'post'
  # }); 
  #
  # var x=myRequest.post({'preset[name]':'new_name'})
  #
  def update
    preset =
      begin
        Meca::RackviewPreset.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        return error_for('preset')
      end
    if cannot? :manage, preset
      return failure_response(preset, AUTH_FAILURE_MESSAGE)
    end

    preset.update(permitted_params)
    preset.save ? success_response(preset) : failure_response(preset)
  end

  # Example JS request to delete a preset
  #
  # var myRequest = new Request({
  #   url: '/--/api/irv/rackview_presets/23',
  #   method: 'post'
  # });
  #
  # var x=myRequest.delete()
  # 
  def destroy
    preset =
      begin
        Meca::RackviewPreset.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        error_for('preset')
      end
    if cannot? :manage, preset
      return failure_response(preset, AUTH_FAILURE_MESSAGE)
    end

    preset.destroy ? success_response(preset) : failure_response(preset)
  end

  private

  PERMITTED_PARAMS = ['name', 'default', 'user_id', { values: {} } ]
  def permitted_params
    params.require(:preset).permit(*PERMITTED_PARAMS)
  end
end
