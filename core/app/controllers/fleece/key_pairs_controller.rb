class Fleece::KeyPairsController < ApplicationController
  def new
    authorize! :create, Fleece::KeyPair
    @user = Uma::User.find(params[:user_id])
    @config = Fleece::Config.first
    if @config.nil?
      flash[:alert] = "Unable to create key pairs: cloud environment config not set"
      redirect_to root_path
      return
    end
    @key_pair = Fleece::KeyPair.new(user: @user)
  end

  def create
    authorize! :create, Fleece::KeyPair
    @config = Fleece::Config.first
    @user = Uma::User.find(params[:user_id])
    @key_pair = @key_pair = Fleece::KeyPair.new(user: @user, name: key_pair_params[:name], key_type: key_pair_params[:key_type])

    if @config.nil?
      flash.now.alert = "Unable to send cluster configuration: cloud environment config not set. Please contact an admin"
      render action: :new
      return
    end

    unless current_user.project_id
      flash.now.alert = "Unable to send key pair request: you do not yet have a project id. " \
                        "This will be added automatically shortly."
      render action: :new
      return
    end

    result = Fleece::CreateKeyPairJob.perform_now(@key_pair, @config, current_user)

    if result.success?
      flash[:success] = "key pair created"
    else
      flash[:error] = result.error_message
    end
    render action: :new
  end

  private

  PERMITTED_PARAMS = %w[name key_type]
  def key_pair_params
    params.require(:fleece_key_pair).permit(*PERMITTED_PARAMS)
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
