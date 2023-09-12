class IrvsController < ApplicationController
  def show
    authorize! :read, Irv
    @show = "full_irv"
  end

  def configuration
    authorize! :read, Irv
    render :json => Irv.get_canvas_config
  end
end
