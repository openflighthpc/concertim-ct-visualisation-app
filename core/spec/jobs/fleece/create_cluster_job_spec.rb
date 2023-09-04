require 'rails_helper'

RSpec.describe Fleece::CreateClusterJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:config) { create(:fleece_config) }
  let(:cluster) { build(:fleece_cluster) }
  let(:user) { create(:user, :with_openstack_details) }
  subject { Fleece::CreateClusterJob::Runner.new(cluster: cluster, fleece_config: config, user: user) }

  describe "url" do
    before(:each) do
      class << subject
        public :connection
        public :path
      end
    end

    it "uses the ip and port given in the config" do
      expect(subject.connection.url_prefix.to_s).to eq "#{config.host_url[0...-5]}:#{config.cluster_builder_port}/"
    end

    it "uses a hard-coded path" do
      expect(subject.path).to eq "/clusters/"
    end
  end

  describe "#perform" do
    context "when request is successful" do
      before(:each) do
        stubs.post("#{config.host_url[0...-5]}:#{config.cluster_builder_port}/clusters/") { |env| [ 200, {}, ""] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(cluster, config, user, test_stubs: stubs)
        expect(result).to be_success
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.post("#{config.host_url[0...-5]}:#{config.cluster_builder_port}/clusters/") { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cluster, config, user, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        pending "faraday test adapter sets reason_phrase to nil"
        result = described_class.perform_now(cluster, config, user, test_stubs: stubs)
        expect(result.error_message).to eq "404 Not Found"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.post("#{config.host_url[0...-5]}:#{config.cluster_builder_port}/clusters/") { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cluster, config, user, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cluster, config, user, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "execution expired"
      end
    end
  end

  describe "body" do
    subject { super().send(:body).with_indifferent_access }

    it 'contains cluster details' do
      expect(subject[:cluster]).to eq({
                                          "cluster_type_id" => cluster.cluster_type.foreign_id,
                                          "name" => cluster.name,
                                          "parameters" => cluster.field_values
                                        })
    end

    it "contains the correct config and user details" do
      expect(subject[:cloud_env]).to eq({
                                          "auth_url" => config.internal_auth_url,
                                          "user_id" => user.cloud_user_id.gsub(/-/, ''),
                                          "password" => user.openstack_password,
                                          "project_id" => user.project_id
                                        })
    end
  end
end
