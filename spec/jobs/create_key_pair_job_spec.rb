require 'rails_helper'

RSpec.describe CreateKeyPairJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:user) { create(:user, :with_openstack_details) }
  let(:path) { "#{cloud_service_config.user_handler_base_url}/key_pairs" }
  let(:key_pair) { build(:key_pair, user: user) }
  subject { CreateKeyPairJob::Runner.new(key_pair: key_pair, cloud_service_config: cloud_service_config, user: user) }

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
      expect(subject.path).to eq "/key_pairs"
    end
  end

  describe "#perform" do
    context "when request is successful" do
      before(:each) do
        stubs.post(path) { |env| [ 200, {}, {"key_pair" => {"private_key" => "abc", "fingerprint" => "abc-123"}}] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(key_pair, cloud_service_config, user, test_stubs: stubs)
        expect(result).to be_success
      end

      it 'populates private key' do
        result = described_class.perform_now(key_pair, cloud_service_config, user, test_stubs: stubs)
        expect(key_pair.private_key).to eq "abc"
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.post(path) { |env| [ 404, {}] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(key_pair, cloud_service_config, user, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(key_pair, cloud_service_config, user, test_stubs: stubs)
        expect(result.error_message).to eq "the server responded with status 404"
      end
    end

    context 'when request has json error response' do
      before(:each) do
        response_body = {"error" => "Conflict", "message" => "Key pair with that name already exists"}.to_json
        stubs.post(path) { |env| [ 409, {"Content-type" => "application/json"}, response_body] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(key_pair, cloud_service_config, user, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(key_pair, cloud_service_config, user, test_stubs: stubs)
        expect(result.error_message).to eq "Key pair with that name already exists"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.post(path) { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(key_pair, cloud_service_config, user, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(key_pair, cloud_service_config, user, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "execution expired"
      end
    end
  end

  describe "body" do
    subject { super().send(:body).with_indifferent_access }

    it 'contains key-pair details' do
      expect(subject[:key_pair]).to eq({
                                        "name" => key_pair.name,
                                        "key_type" => key_pair.key_type,
                                        "public_key" => key_pair.public_key
                                      })
    end

    it "contains the correct config and user details" do
      expect(subject[:cloud_env]).to eq({
                                          "auth_url" => cloud_service_config.internal_auth_url,
                                          "user_id" => user.cloud_user_id,
                                          "password" => user.foreign_password,
                                          "project_id" => user.project_id
                                        })
    end
  end
end
