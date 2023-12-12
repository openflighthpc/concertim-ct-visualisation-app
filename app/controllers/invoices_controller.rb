require 'pagy/delayed_count'

class InvoicesController < ApplicationController
  include ControllerConcerns::Pagination

  before_action :redirect_if_root
  before_action :ensure_cloud_service_configured
  before_action :ensure_billing_account_configured

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
      redirect_to invoices_path
    end
  end

  def draft
    result = GetDraftInvoiceJob.perform_now(@cloud_service_config, current_user)
    if result.success?
      @invoice = result.invoice
      render action: :show
    else
      flash[:alert] = "Unable to fetch draft invoice: #{result.error_message}"
      redirect_to invoices_path
    end
  end

  private

  def redirect_if_root
    if current_user.root?
      flash[:alert] = "Unable to fetch invoice for admin user"
      redirect_back_or_to root_path
    end
  end

  def ensure_cloud_service_configured
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config.nil?
      flash.now[:alert] = "Unable to fetch invoice: cloud environment config
        not set. Please contact an admin."
      render action: :index
    end
  end

  def ensure_billing_account_configured
    if current_user.billing_acct_id.blank?
      flash.now[:alert] = "Unable to fetch invoices. You do not yet have a " \
        "billing account id. This will be added automatically shortly."
      render action: :index
    end
  end
end
