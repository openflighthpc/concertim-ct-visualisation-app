module Ivy
  class IrvsController < Ivy::ApplicationController
    def show
      authorize! :read, Ivy::Irv
      @show = "full_irv"
    end

    def configuration
      authorize! :read, Ivy::Irv
      render :json => Ivy::Irv.get_canvas_config
    end
  end
end
