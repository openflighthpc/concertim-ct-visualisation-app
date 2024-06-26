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
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

require 'rails_helper'

RSpec.describe SyncAllClusterTypesJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  subject { SyncAllClusterTypesJob::Runner.new(cloud_service_config: cloud_service_config) }

  describe "url" do
    before(:each) do
      class << subject
        public :connection
        public :path
      end
    end

    it "uses the host URL and cluster build port given in the config" do
      expected_url = "#{cloud_service_config.cluster_builder_base_url}/"
      expect(subject.connection.url_prefix.to_s).to eq expected_url
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
          parameter_groups: {},
          title: "Fault-Tolerant Web Hosting",
          order: 100,
          logo_url: '/images/cluster-types/testing-cluster-one.svg',
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
          parameter_groups: {},
          title: "My testing cluster type",
          order: 100,
          logo_url: '/images/cluster-types/testing-cluster-two.svg',
        }
      end

      before(:each) do
        url = cloud_service_config.cluster_builder_base_url
        stubs.get("#{url}/cluster-types/") { |env| [ 200, {}, response] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(cloud_service_config, test_stubs: stubs)
        expect(result).to be_success
      end

      context 'new cluster types' do
        let(:response) { [cluster_one_details, cluster_two_details].as_json }

        it 'creates both cluster types' do
          expect(ClusterType.count).to eq 0
          result = described_class.perform_now(cloud_service_config, test_stubs: stubs)
          expect(result).to be_success
          expect(ClusterType.count).to eq 2
          cluster_one = ClusterType.first
          expect(cluster_one.name).to eq "Fault-Tolerant Web Hosting"
          expect(cluster_one.description).to eq "Cluster one"
          expect(cluster_one.foreign_id).to eq "testing-cluster-one"
          expect(cluster_one.fields.length).to eq 1

          cluster_one = ClusterType.last
          expect(cluster_one.name).to eq "My testing cluster type"
          expect(cluster_one.description).to eq "A template showing how to create a highly powered supercomputer"
          expect(cluster_one.foreign_id).to eq "testing-cluster-two"
          expect(cluster_one.fields.length).to eq 2
        end
      end

      context 'cluster type changes' do
        let!(:existing_type) { create(:cluster_type, foreign_id: cluster_one_details[:id]) }
        let(:response) { [cluster_one_details, cluster_two_details].as_json }

        it 'updates changed cluster type' do
          expect(ClusterType.count).to eq 1
          result = described_class.perform_now(cloud_service_config, test_stubs: stubs)
          expect(result).to be_success
          expect(ClusterType.count).to eq 2
          cluster_one = ClusterType.first
          expect(cluster_one.name).to eq "Fault-Tolerant Web Hosting"
          expect(cluster_one.description).to eq "Cluster one"
          expect(cluster_one.foreign_id).to eq "testing-cluster-one"
          expect(cluster_one.fields.length).to eq 1

          cluster_one = ClusterType.last
          expect(cluster_one.name).to eq "My testing cluster type"
          expect(cluster_one.description).to eq "A template showing how to create a highly powered supercomputer"
          expect(cluster_one.foreign_id).to eq "testing-cluster-two"
          expect(cluster_one.fields.length).to eq 2
        end
      end

      context 'removing cluster type' do
        let!(:existing_type) { create(:cluster_type, foreign_id: cluster_one_details[:id]) }
        let(:response) { [cluster_two_details].as_json }

        it 'deletes cluster type no longer in list' do
          expect(ClusterType.count).to eq 1
          result = described_class.perform_now(cloud_service_config, test_stubs: stubs)
          expect(result).to be_success
          expect(ClusterType.count).to eq 1
          cluster_one = ClusterType.first
          expect(cluster_one.name).to eq "My testing cluster type"
          expect(cluster_one.description).to eq "A template showing how to create a highly powered supercomputer"
          expect(cluster_one.foreign_id).to eq "testing-cluster-two"
          expect(cluster_one.fields.length).to eq 2
        end
      end
    end

    context "when request returns a 304" do
      before(:each) do
        url = cloud_service_config.cluster_builder_base_url
        stubs.get("#{url}/cluster-types/") { |env| [ 304, {}, ""] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(cloud_service_config, test_stubs: stubs)
        expect(result).to be_success
      end

      context 'with existing cluster type' do
        let!(:existing_type) { create(:cluster_type) }

        it 'does not alter existing type' do
          existing_type.reload
          result = described_class.perform_now(cloud_service_config, test_stubs: stubs)
          expect(result).to be_success
          expect(existing_type.previous_changes.blank?).to eq true
          expect(existing_type.destroyed?).to eq false
        end
      end
    end

    context "when request is not successful" do
      before(:each) do
        url = cloud_service_config.cluster_builder_base_url
        stubs.get("#{url}/cluster-types/") { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, test_stubs: stubs)
        expect(result.error_message).to eq "Unable to update cluster types: the server responded with status 404"
      end
    end

    context "when request times out" do
      before(:each) do
        url = cloud_service_config.cluster_builder_base_url
        stubs.get("#{url}/cluster-types/") { |env| sleep timeout * 2 ; [ 200, {}, []] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "Unable to update cluster types: execution expired"
      end
    end
  end

  include_examples 'auth token header'
end
