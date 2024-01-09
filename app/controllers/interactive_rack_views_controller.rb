class InteractiveRackViewsController < ApplicationController

  def show
    # TODO
    # If non root user has no teams, they should be redirected/ shown a page
    # telling them this

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
