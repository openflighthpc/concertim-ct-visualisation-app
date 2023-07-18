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
      Fleece::ConfigCreatedJob.perform_later(@config)
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

  private

  PERMITTED_PARAMS = %w[admin_user_id admin_password admin_project_id host_url internal_auth_url user_handler_port cluster_builder_port]
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
