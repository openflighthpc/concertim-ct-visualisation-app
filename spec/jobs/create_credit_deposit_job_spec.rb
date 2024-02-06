require 'rails_helper'

RSpec.describe CreateCreditDepositJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:user) { create(:user, :with_openstack_details) }
  let(:path) { "#{cloud_service_config.user_handler_base_url}/credits" }
  let(:credit_deposit) { build(:credit_deposit, user: user) }
  subject { CreateCreditDepositJob::Runner.new(credit_deposit: credit_deposit, cloud_service_config: cloud_service_config, user: user) }

  describe "url" do
    before(:each) do
      class << subject
        public :connection
        public :path
      end
    end

    it "uses the ip and port given in the config" do
      expect(subject.connection.url_prefix.to_s).to eq "#{cloud_service_config.user_handler_base_url}/"
    end

    it "uses a hard-coded path" do
      expect(subject.path).to eq "/credits"
    end
  end

  describe "#perform" do
    context "when request is successful" do
      before(:each) do
        stubs.post(path) { |env| [ 200, {}, {}] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(credit_deposit, cloud_service_config, user, test_stubs: stubs)
        expect(result).to be_success
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.post(path) { |env| [ 404, {}] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(credit_deposit, cloud_service_config, user, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(credit_deposit, cloud_service_config, user, test_stubs: stubs)
        expect(result.error_message).to eq "the server responded with status 404"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.post(path) { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(credit_deposit, cloud_service_config, user, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(credit_deposit, cloud_service_config, user, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "execution expired"
      end
    end
  end

  describe "body" do
    subject { super().send(:body).with_indifferent_access }

    it 'contains credit deposit details' do
      expect(subject).to eq({
                                         "billing_acct_id" => credit_deposit.billing_acct_id,
                                         "amount" => credit_deposit.amount
                                       })
    end
  end

  include_examples 'auth token header'
end
