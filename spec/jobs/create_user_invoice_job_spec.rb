require 'rails_helper'

RSpec.describe CreateUserInvoiceJob, type: :job do

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:user) { create(:user, :with_openstack_details) }

  subject(:job_runner) {
    described_class::Runner.new(user: user, cloud_service_config: cloud_service_config, test_stubs: stubs)
  }

  let(:user_invoice_path) { "/get_user_invoice" }
  let(:expected_url) {
    "#{cloud_service_config.user_handler_base_url}#{user_invoice_path}"
  }

  describe "url" do
    subject { super().send(:url) }

    it "uses the correct ip, port and path" do
      expect(subject).to eq expected_url
    end
  end

  describe "body" do
    subject { super().send(:body).with_indifferent_access }

    it "contains the correct cloud environment config" do
      expect(subject[:cloud_env]).to eq({
        "auth_url" => cloud_service_config.internal_auth_url,
        "user_id" => user.cloud_user_id,
        "password" => user.foreign_password,
        "project_id" => user.project_id,
      })
    end

    it "contains invoice config" do
      expect(subject[:invoice]).to eq({
        "billing_acct_id" => user.billing_acct_id,
        "target_date" => "#{Date.today.year}-#{Date.today.month}-#{"%02d" % Date.today.day}",
      })
    end
  end

  describe "#perform" do
    context "when request is successful" do
      before(:each) do
        stubs.post(expected_url) { |env| [ 200, {}, {"invoice_html" => invoice_document}] }
      end

      let(:invoice_document) {
        "<html><head></head><body><h1>This is your invoice</h1></body></html>"
      }

      it "returns a successful result" do
        result = described_class.perform_now(cloud_service_config, user, test_stubs: stubs)
        expect(result).to be_success
      end

      it "contains the invoice document in the result" do
        result = described_class.perform_now(cloud_service_config, user, test_stubs: stubs)
        expect(result.invoice).to eq invoice_document
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.post(expected_url) { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, user, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, user, test_stubs: stubs)
        expect(result.error_message).to eq "the server responded with status 404"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.post(expected_url) { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, user, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, user, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "execution expired"
      end
    end
  end
end