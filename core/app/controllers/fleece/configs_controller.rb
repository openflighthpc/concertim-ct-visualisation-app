class Fleece::ConfigsController < ApplicationController
  before_action :load_config
  authorize_resource :config

  def show
    if @config.nil? || !@config.persisted?
      redirect_to new_fleece_config_path
    end
  end

  def new
    redirect_to edit_fleece_config_path if @config.persisted?
  end

  def create
    if @config.update(config_params)
      flash[:success] = "Cloud environment config created"
      redirect_to fleece_config_path
    else
      render action: :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to new_fleece_config_path if @config.nil? || !@config.persisted?
  end

  def update
    if @config.update(config_params)
      flash[:success] = "Cloud environment config updated"
      redirect_to fleece_config_path
    else
      render action: :edit, status: :unprocessable_entity
    end
  end

  # POST the config to the ip/port specified in the config
  def send_config
    if @config.nil? || !@config.persisted?
      flash[:alert] = "Unable to send cloud environment configuration it has not yet been created."
      redirect_to action: :show
      return
    end

    result = Fleece::PostConfigJob.perform_now(@config)
    if result.success?
      flash[:success] = "Cloud environment configuration sent"
    else
      flash[:alert] = "Unable to send configuration: #{result.error_message}"
    end
    redirect_to action: :show
  end

  private

  PERMITTED_PARAMS = %w[host_name host_ip username password port project_name domain_name]
  def config_params
    params.require(:fleece_config).permit(*PERMITTED_PARAMS)
  end

  def load_config
    @config = Fleece::Config.first

    if params[:action] == 'new'
      @config ||= Fleece::Config.new
    end
    if params[:action] == 'create'
      raise "Only a single config is supported" unless @config.nil?
      @config = Fleece::Config.new
    end
  end
end
