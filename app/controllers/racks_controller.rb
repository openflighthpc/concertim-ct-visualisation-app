class RacksController < ApplicationController
  include ControllerConcerns::ResourceTable
  load_and_authorize_resource :rack, class: 'HwRack'

  def show
  end

  def devices
    @devices = resource_table_collection(@rack.devices, model: Device)
  end

  def instructions
    @instruction_id = params[:instruction_id]
  end
end
