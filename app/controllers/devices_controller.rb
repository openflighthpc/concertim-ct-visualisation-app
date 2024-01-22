class DevicesController < ApplicationController
  load_and_authorize_resource :device

  def show
    @device = DevicePresenter.new(@device, self.view_context)
  end
end
