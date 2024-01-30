class InteractiveRackViewsController < ApplicationController

  def show
    authorize! :read, InteractiveRackView
    @show = "full_irv"
    if params[:rack_ids].present?
      @rack_ids = Array(params[:rack_ids])
    end
  end

  def configuration
    authorize! :read, InteractiveRackView
    render :json => InteractiveRackView.get_canvas_config
  end
end
