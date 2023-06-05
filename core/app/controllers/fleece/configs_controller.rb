class Fleece::ConfigsController < ApplicationController
  before_action :load_config
  authorize_resource :config

  def show
    if @config.nil? || !@config.persisted?
      redirect_to new_fleece_configs_path
    end
  end

  def create
    if @config.update(config_params)
      flash[:notice] = "Cloud environment config created"
      redirect_to fleece_configs_path
    else
      render action: :new
    end
  end

  def edit
    redirect_to new_fleece_configs_path if @config.nil?
  end

  def update
    if @config.update(config_params)
      flash[:notice] = "Cloud environment config updated"
      redirect_to fleece_configs_path
    else
      render action: :edit
    end
  end

  private

  PERMITTED_PARAMS = %w[host_name host_ip username password port project_name domain_name]
  def config_params
    params.require(:fleece_config).permit(*PERMITTED_PARAMS)
  end

  def load_config
    @config = Fleece::Config.first

    if params[:action] == 'new' || params[:action] == 'create'
      raise "Only a single config is supported" unless @config.nil?
      @config = Fleece::Config.new
    end
  end
end
