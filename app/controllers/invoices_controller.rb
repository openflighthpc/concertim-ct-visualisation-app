class InvoicesController < ApplicationController
  def show
    if current_user.root?
      flash[:alert] = "Unable to fetch invoice for admin user"
      redirect_back_or_to root_path
      return
    end
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config.nil?
      flash[:alert] = "Unable to fetch user's invoice: cloud environment config
        not set. Please contact an admin."
      redirect_back_or_to root_path
      return
    end
    unless current_user.billing_acct_id
      flash[:alert] = "Unable to fetch user's invoice: you do not yet have a " \
        "billing account id. This will be added automatically shortly."
      redirect_back_or_to root_path
      return
    end

    result = CreateUserInvoiceJob.perform_now(@cloud_service_config, current_user)
    if result.success?
      render status: 200, html: result.invoice.html_safe
    else
      flash[:alert] = "Unable to fetch user's invoice: #{result.error_message}"
      redirect_back_or_to root_path
      return
    end
  end
end
