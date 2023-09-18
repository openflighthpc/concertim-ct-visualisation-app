class KeyPairsController < ApplicationController
  def new
    authorize! :create, KeyPair
    @user = current_user
    @config = CloudServiceConfig.first
    if @config.nil?
      flash[:alert] = "Unable to create key-pairs: cloud environment config not set"
      redirect_to root_path
      return
    end
    @key_pair = KeyPair.new(user: @user)
  end

  def index
    @config = CloudServiceConfig.first
    if @config.nil?
       flash[:alert] = "Unable to check key-pairs: cloud environment config not set. Please contact an admin"
       redirect_to edit_user_registration_path
       return
    end

    unless current_user.project_id
      flash[:alert] = "Unable to check key-pairs: you do not yet have a project id. " \
                      "This will be added automatically shortly."
      redirect_to edit_user_registration_path
      return
    end

    result = GetUserKeyPairsJob.perform_now(@config, current_user)
    if result.success?
      @key_pairs = result.key_pairs
    else
      flash[:alert] = "Unable to get key-pairs: #{result.error_message}"
      redirect_to edit_user_registration_path
      return
    end
  end

  def create
    @config = CloudServiceConfig.first
    @user = current_user
    public_key = key_pair_params[:public_key].blank? ? nil : key_pair_params[:public_key]
    @key_pair = @key_pair = KeyPair.new(user: @user, name: key_pair_params[:name], key_type: key_pair_params[:key_type],
                                                public_key: public_key)
    authorize! :create, @key_pair

    if @config.nil?
      flash[:alert] = "Unable to send key-pair requests: cloud environment config not set. Please contact an admin"
      redirect_to edit_user_registration_path
      return
    end

    unless current_user.project_id
      flash[:alert] = "Unable to send key-pair request: you do not yet have a project id. " \
                      "This will be added automatically shortly."
      redirect_to edit_user_registration_path
      return
    end

    result = CreateKeyPairJob.perform_now(@key_pair, @config, current_user)

    if result.success?
      render action: :success
    else
      flash[:alert] = result.error_message
      redirect_to key_pairs_path
    end
  end

  def destroy
    authorize! :destroy, KeyPair.new(user: current_user)
    @config = CloudServiceConfig.first
    @user = current_user
    if @config.nil?
      flash[:alert] = "Unable to send key-pair requests: cloud environment config not set. Please contact an admin"
      redirect_to edit_user_registration_path
      return
    end

    unless current_user.project_id
      flash[:alert] = "Unable to send key-pair deletion request: you do not yet have a project id. " \
                      "This will be added automatically shortly."
      redirect_to edit_user_registration_path
      return
    end

    result = DeleteKeyPairJob.perform_now(params[:name], @config, current_user)

    if result.success?
      flash[:success] = "Key-pair '#{params[:name]}' deleted"
    else
      flash[:alert] = result.error_message
    end
    redirect_to key_pairs_path
  end

  private

  PERMITTED_PARAMS = %w[name key_type public_key]
  def key_pair_params
    params.require(:key_pair).permit(*PERMITTED_PARAMS)
  end
end
