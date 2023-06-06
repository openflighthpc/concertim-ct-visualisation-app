class Api::V1::Fleece::ConfigsController < Api::V1::ApplicationController
  def show
    authorize! :read, ::Fleece::Config
    @config = ::Fleece::Config.first
    raise ActiveRecord::RecordNotFound if @config.nil?
  end
end
