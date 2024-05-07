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

RSpec.describe SyncIndividualClusterTypeJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:cluster_type) { create(:cluster_type) }
  subject { SyncIndividualClusterTypeJob::Runner.new(cloud_service_config: cloud_service_config, cluster_type: cluster_type) }

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
        parameter_groups: [],
        title: "Fault-Tolerant Web Hosting",
        order: 100,
        logo_url: '/images/cluster-types/testing-cluster-one.svg',
      }
    end
    let!(:cluster_type) do
      create(
        :cluster_type, foreign_id: cluster_details[:id], description: cluster_details[:description],
        version: cluster_details[:last_modified], name: cluster_details[:title], fields: cluster_details[:parameters]
      )
    end

    context "when request is successful" do
      let(:response) { cluster_details.as_json }

      before(:each) do
        url = cloud_service_config.cluster_builder_base_url
        stubs.get("#{url}/cluster-types/#{cluster_type.foreign_id}") do |env|
          [ 200, {}, response]
        end
      end

      it "returns a successful result" do
        result = described_class.perform_now(cloud_service_config, cluster_type, test_stubs: stubs)
        expect(result).to be_success
      end

      context 'cluster type changes' do
        before(:each) do
          cluster_details[:description] = "new description"
        end

        it 'updates changed cluster type' do
          expect(ClusterType.count).to eq 1
          result = described_class.perform_now(cloud_service_config, cluster_type, test_stubs: stubs)
          expect(result).to be_success
          expect(ClusterType.count).to eq 1
          expect(cluster_type.reload.description).to eq "new description"
          expect(cluster_type.foreign_id).to eq "testing-cluster-one"
        end
      end
    end

    context "when request returns a 304" do
      before(:each) do
        url = cloud_service_config.cluster_builder_base_url
        stubs.get("#{url}/cluster-types/#{cluster_type.foreign_id}") do |env|
          [ 304, {}, ""]
        end
      end

      it "returns a successful result" do
        result = described_class.perform_now(cloud_service_config, cluster_type, test_stubs: stubs)
        expect(result).to be_success
      end

      it 'does not alter existing type' do
        cluster_type.reload
        result = described_class.perform_now(cloud_service_config, cluster_type, test_stubs: stubs)
        expect(result).to be_success
        expect(cluster_type.previous_changes.blank?).to eq true
        expect(cluster_type.destroyed?).to eq false
      end
    end

    context "when request is not successful" do
      before(:each) do
        url = cloud_service_config.cluster_builder_base_url
        stubs.get("#{url}/cluster-types/#{cluster_type.foreign_id}") do |env|
          [ 404, {}, "404 Not Found"]
        end
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, cluster_type, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, cluster_type, test_stubs: stubs)
        expect(result.error_message).to eq "Unable to update cluster type: the server responded with status 404"
      end
    end

    context "when request times out" do
      before(:each) do
        url = cloud_service_config.cluster_builder_base_url
        stubs.get("#{url}/cluster-types/#{cluster_type.foreign_id}") do |env|
          sleep timeout * 2 ; [ 200, {}, []]
        end
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, cluster_type, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, cluster_type, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "Unable to update cluster type: execution expired"
      end
    end
  end

  include_examples 'auth token header'
end
