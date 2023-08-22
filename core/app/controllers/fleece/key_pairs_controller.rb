class Fleece::KeyPairsController < ApplicationController
  def new
    authorize! :create, Fleece::KeyPair
    @user = current_user
    @config = Fleece::Config.first
    if @config.nil?
      flash[:alert] = "Unable to create key pairs: cloud environment config not set"
      redirect_to root_path
      return
    end
    @key_pair = Fleece::KeyPair.new(user: @user)
  end

  def index
    @config = Fleece::Config.first
    # at the moment this job does not work due to an error with openstack
    # result = Fleece::GetUserKeyPairsJob.perform_now(@config, current_user)
    # if result.success?
    #   @key_pairs = result.key_pairs
    # end
    @key_pairs = current_user.key_pairs
  end

  def create
    authorize! :create, Fleece::KeyPair
    @config = Fleece::Config.first
    @user = current_user
    public_key = key_pair_params[:public_key].blank? ? nil : key_pair_params[:public_key]
    @key_pair = @key_pair = Fleece::KeyPair.new(user: @user, name: key_pair_params[:name], key_type: key_pair_params[:key_type],
                                                public_key: public_key)

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
      flash[:alert] = result.error_message
      redirect_to key_pairs_path
      return
    end
    render action: :success
  end

  private

  PERMITTED_PARAMS = %w[name key_type public_key]
  def key_pair_params
    params.require(:fleece_key_pair).permit(*PERMITTED_PARAMS)
  end
end
