class InteractiveRackViewsController < ApplicationController
  def show
    authorize! :read, InteractiveRackView
    @show = "full_irv"
  end

  def configuration
    authorize! :read, InteractiveRackView
    render :json => InteractiveRackView.get_canvas_config
  end
end
