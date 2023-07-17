require 'rails_helper'

RSpec.describe Fleece::SyncAllClusterTypesJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:config) { create(:fleece_config) }
  subject { Fleece::SyncAllClusterTypesJob::Runner.new(fleece_config: config) }

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

    it "uses a hard-coded path" do
      expect(subject.path).to eq "/cluster-types/"
    end
  end

  describe "#perform" do
    context "when request is successful" do
      let(:response) { [] }
      let(:cluster_one_details) do
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
              type: "string"
            },
          },
          title: "Fault-Tolerant Web Hosting"
        }
      end
      let(:cluster_two_details) do
        {
          description: "A template showing how to create a highly powered supercomputer",
          id: "testing-cluster-two",
          last_modified: "Wed, 12 Jul 2023 15:17:31 GMT",
          parameters: {
            db_name: {
              constraints: [
                {
                  description: "db_name must be between 1 and 64 characters",
                  length: {
                    max: 64,
                    min: 1
                  }
                },
                {
                  allowed_pattern: "[a-zA-Z][a-zA-Z0-9]*",
                  description: "db_name must begin with a letter and contain only alphanumeric characters\n"
                }
              ],
              default: "records",
              description: "Cluster database name",
              type: "string"
            },
            db_password: {
              constraints: [
                {
                  description: "db_password must be between 1 and 41 characters",
                  length: {
                    max: 41,
                    min: 1
                  }
                },
                {
                  allowed_pattern: "[a-zA-Z0-9]*",
                  description: "db_password must contain only alphanumeric characters"
                }
              ],
              default: "admin",
              description: "The database admin account password",
              hidden: true,
              type: "string"
            },
          },
          title: "My testing cluster type"
        }
      end

      before(:each) do
        stubs.get("http://#{config.host_ip}:#{config.cluster_builder_port}/cluster-types/") { |env| [ 200, {}, response] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(config, test_stubs: stubs)
        expect(result).to be_success
      end

      context 'new cluster types' do
        let(:response) { [cluster_one_details, cluster_two_details].as_json }

        it 'creates both cluster types' do
          expect(Fleece::ClusterType.count).to eq 0
          result = described_class.perform_now(config, test_stubs: stubs)
          expect(result).to be_success
          expect(Fleece::ClusterType.count).to eq 2
          cluster_one = Fleece::ClusterType.first
          expect(cluster_one.name).to eq "Fault-Tolerant Web Hosting"
          expect(cluster_one.description).to eq "Cluster one"
          expect(cluster_one.foreign_id).to eq "testing-cluster-one"
          expect(cluster_one.fields.length).to eq 1

          cluster_one = Fleece::ClusterType.last
          expect(cluster_one.name).to eq "My testing cluster type"
          expect(cluster_one.description).to eq "A template showing how to create a highly powered supercomputer"
          expect(cluster_one.foreign_id).to eq "testing-cluster-two"
          expect(cluster_one.fields.length).to eq 2
        end
      end

      context 'cluster type changes' do
        let!(:existing_type) { create(:fleece_cluster_type, foreign_id: cluster_one_details[:id]) }
        let(:response) { [cluster_one_details, cluster_two_details].as_json }

        it 'updates changed cluster type' do
          expect(Fleece::ClusterType.count).to eq 1
          result = described_class.perform_now(config, test_stubs: stubs)
          expect(result).to be_success
          expect(Fleece::ClusterType.count).to eq 2
          cluster_one = Fleece::ClusterType.first
          expect(cluster_one.name).to eq "Fault-Tolerant Web Hosting"
          expect(cluster_one.description).to eq "Cluster one"
          expect(cluster_one.foreign_id).to eq "testing-cluster-one"
          expect(cluster_one.fields.length).to eq 1

          cluster_one = Fleece::ClusterType.last
          expect(cluster_one.name).to eq "My testing cluster type"
          expect(cluster_one.description).to eq "A template showing how to create a highly powered supercomputer"
          expect(cluster_one.foreign_id).to eq "testing-cluster-two"
          expect(cluster_one.fields.length).to eq 2
        end
      end

      context 'removing cluster type' do
        let!(:existing_type) { create(:fleece_cluster_type, foreign_id: cluster_one_details[:id]) }
        let(:response) { [cluster_two_details].as_json }

        it 'deletes cluster type no longer in list' do
          expect(Fleece::ClusterType.count).to eq 1
          result = described_class.perform_now(config, test_stubs: stubs)
          expect(result).to be_success
          expect(Fleece::ClusterType.count).to eq 1
          cluster_one = Fleece::ClusterType.first
          expect(cluster_one.name).to eq "My testing cluster type"
          expect(cluster_one.description).to eq "A template showing how to create a highly powered supercomputer"
          expect(cluster_one.foreign_id).to eq "testing-cluster-two"
          expect(cluster_one.fields.length).to eq 2
        end
      end
    end

    context "when request returns a 304" do
      before(:each) do
        stubs.get("http://#{config.host_ip}:#{config.cluster_builder_port}/cluster-types/") { |env| [ 304, {}, ""] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(config, test_stubs: stubs)
        expect(result).to be_success
      end

      context 'with existing cluster type' do
        let!(:existing_type) { create(:fleece_cluster_type) }

        it 'does not alter existing type' do
          existing_type.reload
          result = described_class.perform_now(config, test_stubs: stubs)
          expect(result).to be_success
          expect(existing_type.previous_changes.blank?).to eq true
          expect(existing_type.destroyed?).to eq false
        end
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.get("http://#{config.host_ip}:#{config.cluster_builder_port}/cluster-types/") { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(config, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        pending "faraday test adapter sets reason_phrase to nil"
        result = described_class.perform_now(config, test_stubs: stubs)
        expect(result.error_message).to eq "404 Not Found"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.get("http://#{config.host_ip}:#{config.cluster_builder_port}/cluster-types/") { |env| sleep timeout * 2 ; [ 200, {}, []] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(config, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(config, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "Unable to update cluster types: execution expired"
      end
    end
  end
end