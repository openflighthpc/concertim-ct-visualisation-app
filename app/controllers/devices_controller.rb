class DevicesController < ApplicationController
  load_and_authorize_resource :device

  def show
  end
end
