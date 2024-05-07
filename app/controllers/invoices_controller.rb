#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

require 'pagy/delayed_count'

class InvoicesController < ApplicationController
  include ControllerConcerns::Pagination

  before_action :set_team
  before_action :ensure_cloud_service_configured
  before_action :ensure_billing_account_configured

  def index
    authorize! :read, Invoice.new(account: @team)
    @pagy = Pagy::DelayedCount.new(pagy_get_vars_without_count)
    result = GetInvoicesJob.perform_now(@cloud_service_config, @team, offset: @pagy.offset, limit: @pagy.items)
    if result.success?
      @pagy.finalize(result.invoices_count)
      @invoices = result.invoices
    else
      flash.now[:alert] = "Unable to fetch invoices: #{result.error_message}"
      @pagy.finalize(0)
      @invoices = []
    end
  end

  def show
    result = GetInvoiceJob.perform_now(@cloud_service_config, @team, params[:id])
    if result.success?
      @invoice = result.invoice
      authorize! :show, @invoice
      render
    else
      flash[:alert] = "Unable to fetch invoice: #{result.error_message}"
      redirect_to team_invoices_path(@team)
    end
  end

  def draft
    result = GetDraftInvoiceJob.perform_now(@cloud_service_config, @team)
    if result.success?
      @invoice = result.invoice
      authorize! :show, @invoice
      render action: :show
    else
      flash[:alert] = "Unable to fetch draft invoice: #{result.error_message}"
      redirect_to team_invoices_path(@team)
    end
  end

  private

  def set_team
    @team = Team.find(params[:team_id])
  end

  def ensure_cloud_service_configured
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config.nil?
      flash.now[:alert] = "Unable to fetch invoice: cloud environment config " \
        "not set. Please contact an admin."
      render action: :index
    end
  end

  def ensure_billing_account_configured
    if @team.billing_acct_id.blank?
      flash.now[:alert] = "Unable to fetch invoices. The team does not yet have a " \
        "billing account id. This will be added automatically shortly."
      render action: :index
    end
  end
end
