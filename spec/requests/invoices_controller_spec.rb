require 'rails_helper'

RSpec.describe "InvoicesControllers", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }
  # let(:user) { create(:user, :with_openstack_details) }

  describe "GET :show" do
    let(:url_under_test) { urls.invoices_path }

    shared_examples "does not fetch invoice" do
      it "redirects to the home page" do
        get url_under_test, headers: headers
        expect(response).to redirect_to urls.root_path
      end

      it "does not fetch an invoice" do
        get url_under_test, headers: headers
        expect(GetDraftInvoiceJob).not_to have_been_enqueued
        expect(GetDraftInvoiceJob).not_to have_been_performed
      end

      # it "displays an error flash" do
      #   pending "follow_redirect! doesn't work due to our use of a `headers` method"
      #   get url_under_test, headers: headers
      #   follow_redirect!
      #   expect(response.body).to include "Unable to fetch invoice for admin user"
      # end
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      include_examples "does not fetch invoice"
    end

    context "when logged in as non-admin" do
      include_context "Logged in as non-admin"

      context "when cloud service has not been configured" do
        before(:each) { CloudServiceConfig.delete_all }
        include_examples "does not fetch invoice"
      end

      context "when user does not have a billing account" do
        before(:each) { expect(authenticated_user.billing_acct_id).to be_nil }
        include_examples "does not fetch invoice"
      end

      context "when prerequisites are met" do
        before(:each) { allow(GetDraftInvoiceJob).to receive(:perform_now).and_return(result) }
        let(:result) { GetDraftInvoiceJob::Result.new(true, invoice_data, authenticated_user, nil, 201) }
        let(:invoice_document) { "<html><head></head><body><h1>This is your invoice</h1></body></html>" }
        let(:authenticated_user) { create(:user, :with_openstack_details) }
        let!(:cloud_service_config) { create(:cloud_service_config) }
        let(:invoice_data) {
          {
            amount: 4,
            balance: 3,
            credit_adj: 0,
            currency: "coffee",
            status: 'DRAFT',
            invoice_date: Date.today.to_formatted_s(:db),
            invoice_id: 3,
            invoice_number: nil,
            items: [],
            refund_adj: 0,
          }.with_indifferent_access
        }

        include_examples "successful HTML response"

        it "fetches an invoice" do
          pending "perform now and have_been_performed do not work together"
          get url_under_test, headers: headers
          expect(GetDraftInvoiceJob).to have_been_performed
        end

        it "displays the invoice" do
          # XXX Re-write this entire file as a system spec.  We'd have much
          # more meaningful specs that way.
          get url_under_test, headers: headers
          expect(response.body).to include("Invoice (draft)")
          expect(response.body).to include("#{Date.today.to_formatted_s(:rfc822)}")
          expect(response.body).not_to include("1.00 coffee")  # Paid
          expect(response.body).not_to include("3.00 coffee")  # Balance
          expect(response.body).to include("4.00 coffee")  # Amount
        end
      end
    end
  end
end
