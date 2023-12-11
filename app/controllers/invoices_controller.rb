require 'pagy/delayed_count'

class InvoicesController < ApplicationController
  include ControllerConcerns::Pagination

  before_action :redirect_if_root
  before_action :redirect_unless_cloud_config
  before_action :redirect_unless_billing_account

  def index
    @pagy = Pagy::DelayedCount.new(pagy_get_vars_without_count)
    result = GetInvoicesJob.perform_now(@cloud_service_config, current_user, offset: @pagy.offset, limit: @pagy.items)
    if result.success?
      @pagy.finalize(result.invoices_count)
      @invoices = result.invoices
      render
    else
      flash[:alert] = "Unable to fetch invoices: #{result.error_message}"
      redirect_back_or_to root_path
      return
    end
  end

  def show
    result = GetInvoiceJob.perform_now(@cloud_service_config, current_user, params[:id])
    if result.success?
      @invoice = result.invoice
      render
    else
      flash[:alert] = "Unable to fetch invoice: #{result.error_message}"
      redirect_back_or_to root_path
      return
    end
  end

  def draft
    result = GetDraftInvoiceJob.perform_now(@cloud_service_config, current_user)
    if result.success?
      @invoice = result.invoice
      render action: :show
    else
      flash[:alert] = "Unable to fetch draft invoice: #{result.error_message}"
      redirect_back_or_to root_path
      return
    end
  end

  private

  def redirect_if_root
    if current_user.root?
      flash[:alert] = "Unable to fetch invoice for admin user"
      redirect_back_or_to root_path
    end
  end

  def redirect_unless_cloud_config
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config.nil?
      flash[:alert] = "Unable to fetch invoice: cloud environment config
        not set. Please contact an admin."
      redirect_back_or_to root_path
    end
  end

  def redirect_unless_billing_account
    unless current_user.billing_acct_id
      flash[:alert] = "Unable to fetch invoice: you do not yet have a " \
        "billing account id. This will be added automatically shortly."
      redirect_back_or_to root_path
    end
  end
end
