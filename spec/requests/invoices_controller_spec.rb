require 'rails_helper'

RSpec.describe "InvoicesControllers", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }

  describe "GET :index" do
    let(:url_under_test) { urls.invoices_path }

    shared_examples "does not fetch invoice" do
      it "does not fetch an invoice" do
        get url_under_test, headers: headers
        expect(GetInvoicesJob).not_to have_been_enqueued
        expect(GetInvoicesJob).not_to have_been_performed
      end
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      include_examples "does not fetch invoice"

      it "redirects to the home page" do
        get url_under_test, headers: headers
        expect(response).to redirect_to urls.root_path
      end
    end

    context "when logged in as non-admin" do
      include_context "Logged in as non-admin"

      context "when cloud service has not been configured" do
        before(:each) { CloudServiceConfig.delete_all }
        include_examples "does not fetch invoice"

        it "displays an error flash" do
          get url_under_test, headers: headers
          expect(response.body).to include "cloud environment config not set"
        end
      end

      context "when user does not have a billing account" do
        before(:each) { create(:cloud_service_config) }
        before(:each) { expect(authenticated_user.billing_acct_id).to be_nil }
        include_examples "does not fetch invoice"

        it "displays an error flash" do
          get url_under_test, headers: headers
          expect(response.body).to include "You do not yet have a billing account id"
        end
      end
    end
  end
end
