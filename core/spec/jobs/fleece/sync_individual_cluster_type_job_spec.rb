require 'rails_helper'

RSpec.describe Fleece::SyncIndividualClusterTypeJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:config) { create(:fleece_config) }
  let(:cluster_type) { create(:fleece_cluster_type) }
  subject { Fleece::SyncIndividualClusterTypeJob::Runner.new(fleece_config: config, cluster_type: cluster_type) }

  describe "url" do
    before(:each) do
      class << subject
        public :connection
        public :path
      end
    end

    it "uses the ip and port given in the config" do
      expect(subject.connection.url_prefix.to_s).to eq "http://#{config.host_ip}:#{config.cluster_builder_port}/"
    end

    it "uses a hard-coded path plus cluster type foreign id" do
      expect(subject.path).to eq "/cluster-types/#{cluster_type.foreign_id}"
    end
  end

  describe "#perform" do
    let(:cluster_details) do
      {
        description: "Cluster one",
        id: "testing-cluster-one",
        last_modified: "Wed, 12 Jul 2023 12:17:31 GMT",
        parameters: {
          flavor_id: {
            constraints: [
              {
                allowed_values: [
                  "m1.small",
                  "m1.medium",
                  "m1.large"
                ]
              }
            ],
            default: "m1.small",
            label: "The flavour to use for the nodes.",
            type: "string",
            order: 0
          },
        },
        title: "Fault-Tolerant Web Hosting",
      }
    end
    let!(:cluster_type) do
      create(
        :fleece_cluster_type, foreign_id: cluster_details[:id], description: cluster_details[:description],
        version: cluster_details[:last_modified], name: cluster_details[:title], fields: cluster_details[:parameters]
      )
    end

    context "when request is successful" do
      let(:response) { cluster_details.as_json }

      before(:each) do
        stubs.get("http://#{config.host_ip}:#{config.cluster_builder_port}/cluster-types/#{cluster_type.foreign_id}") do |env|
          [ 200, {}, response]
        end
      end

      it "returns a successful result" do
        result = described_class.perform_now(config, cluster_type, test_stubs: stubs)
        expect(result).to be_success
      end

      context 'cluster type changes' do
        before(:each) do
          cluster_details[:description] = "new description"
        end

        it 'updates changed cluster type' do
          expect(Fleece::ClusterType.count).to eq 1
          result = described_class.perform_now(config, cluster_type, test_stubs: stubs)
          expect(result).to be_success
          expect(Fleece::ClusterType.count).to eq 1
          expect(cluster_type.reload.description).to eq "new description"
          expect(cluster_type.foreign_id).to eq "testing-cluster-one"
        end
      end
    end

    context "when request returns a 304" do
      before(:each) do
        stubs.get("http://#{config.host_ip}:#{config.cluster_builder_port}/cluster-types/#{cluster_type.foreign_id}") do |env|
          [ 304, {}, ""]
        end
      end

      it "returns a successful result" do
        result = described_class.perform_now(config, cluster_type, test_stubs: stubs)
        expect(result).to be_success
      end

      it 'does not alter existing type' do
        cluster_type.reload
        result = described_class.perform_now(config, cluster_type, test_stubs: stubs)
        expect(result).to be_success
        expect(cluster_type.previous_changes.blank?).to eq true
        expect(cluster_type.destroyed?).to eq false
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.get("http://#{config.host_ip}:#{config.cluster_builder_port}/cluster-types/#{cluster_type.foreign_id}") do |env|
          [ 404, {}, "404 Not Found"]
        end
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(config, cluster_type, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        pending "faraday test adapter sets reason_phrase to nil"
        result = described_class.perform_now(config, cluster_type, test_stubs: stubs)
        expect(result.error_message).to eq "404 Not Found"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.get("http://#{config.host_ip}:#{config.cluster_builder_port}/cluster-types/#{cluster_type.foreign_id}") do |env|
          sleep timeout * 2 ; [ 200, {}, []]
        end
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(config, cluster_type, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(config, cluster_type, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "Unable to update cluster type: execution expired"
      end
    end
  end
end
