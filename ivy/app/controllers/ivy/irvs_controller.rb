module Ivy
  class IrvsController < Ivy::ApplicationController
    def show
      @show = "full_irv"
    end

    def configuration
      render :json => Ivy::Irv.get_canvas_config
    end
  end
end
