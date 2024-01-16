class CreditDepositsController < ApplicationController
  def new
    @user = User.find(params[:id])
    @credit_deposit = CreditDeposit.new(user: @user)
    authorize! :create, @credit_deposit
    @cloud_service_config = CloudServiceConfig.first
    check_config_and_external_ids
  end

  def create
    @user = User.find(params[:id])
    @cloud_service_config = CloudServiceConfig.first
    @credit_deposit = CreditDeposit.new(user: @user, amount: credit_deposit_params[:amount])
    authorize! :create, @credit_deposit

    if check_config_and_external_ids
      unless @credit_deposit.valid?
        render action: :new
        return
      end

      result = CreateCreditDepositJob.perform_now(@credit_deposit, @cloud_service_config, @user)
      if result.success?
        flash[:success] = "Credit deposit submitted for #{@user.name}. It may take a few minutes for the user's new balance to be reflected."
        redirect_to users_path
      else
        flash.now[:alert] = "Unable to submit credit deposit: #{result.error_message}"
        render :new
      end
    end
  end

  private

  PERMITTED_PARAMS = %w[amount]
  def credit_deposit_params
    params.require(:credit_deposit).permit(*PERMITTED_PARAMS)
  end

  def check_config_and_external_ids
    redirect = false
    if @cloud_service_config.nil?
      flash[:alert] = "Unable to add credits: cloud environment config not set"
      redirect = true
    elsif @user.project_id.nil?
      flash[:alert] = "Unable to add credits: user does not yet have a project id. " \
                      "This should be added automatically shortly."
      redirect = true
    elsif @user.billing_acct_id.nil?
      flash[:alert] = "Unable to add credits: user does not yet have a billing account id. " \
                      "This should be added automatically shortly."
      redirect = true
    end

    if redirect
      redirect_to users_path
      false
    else
      true
    end
  end
end
