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

require 'rails_helper'

RSpec.describe "InvoicesControllers", type: :request do
  let(:headers) { {} }
  let(:team) { create(:team) }
  let(:urls) { Rails.application.routes.url_helpers }

  describe "GET :index" do
    let(:url_under_test) { urls.team_invoices_path(team) }

    shared_examples 'fetching invoices' do
      shared_examples "does not fetch invoice" do
        it "does not fetch an invoice" do
          get url_under_test, headers: headers
          expect(GetInvoicesJob).not_to have_been_enqueued
          expect(GetInvoicesJob).not_to have_been_performed
        end
      end

      context "when cloud service has not been configured" do
        before(:each) { CloudServiceConfig.delete_all }
        include_examples "does not fetch invoice"

        it "displays an error flash" do
          get url_under_test, headers: headers
          expect(response.body).to include "cloud environment config not set"
        end
      end

      context "when team does not have a billing account" do
        before(:each) { create(:cloud_service_config) }
        before(:each) { expect(team.billing_acct_id).to be_nil }
        include_examples "does not fetch invoice"

        it "displays an error flash" do
          get url_under_test, headers: headers
          expect(response.body).to include "The team does not yet have a billing account id."
        end
      end
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      include_examples "fetching invoices"
    end

    context "when logged in as non-admin" do
      include_context "Logged in as non-admin"
      include_examples "fetching invoices"
    end
  end
end
