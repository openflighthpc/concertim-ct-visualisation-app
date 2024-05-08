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

RSpec.describe CreateClusterJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:cluster) { build(:cluster) }
  let(:user) { create(:user, :with_openstack_account) }
  subject { CreateClusterJob::Runner.new(cluster: cluster, cloud_service_config: cloud_service_config, user: user) }

  describe "url" do
    before(:each) do
      class << subject
        public :connection
        public :path
      end
    end

    it "uses the ip and port given in the config" do
      expect(subject.connection.url_prefix.to_s).to eq "#{cloud_service_config.cluster_builder_base_url}/"
    end

    it "uses a hard-coded path" do
      expect(subject.path).to eq "/clusters/"
    end
  end

  describe "#perform" do
    context "when request is successful" do
      before(:each) do
        stubs.post("#{cloud_service_config.cluster_builder_base_url}/clusters/") { |env| [ 200, {}, ""] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(cluster, cloud_service_config, user, test_stubs: stubs)
        expect(result).to be_success
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.post("#{cloud_service_config.cluster_builder_base_url}/clusters/") { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cluster, cloud_service_config, user, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cluster, cloud_service_config, user, test_stubs: stubs)
        expect(result.error_message).to eq "the server responded with status 404"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.post("#{cloud_service_config.cluster_builder_base_url}/clusters/") { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cluster, cloud_service_config, user, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cluster, cloud_service_config, user, test_stubs: stubs, timeout: timeout)
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
                                          "parameters" => cluster.field_values,
                                          "selections" => cluster.selections,
                                        })
    end

    it "contains the correct config and user details" do
      expect(subject[:cloud_env]).to eq({
                                          "auth_url" => cloud_service_config.internal_auth_url,
                                          "user_id" => user.cloud_user_id,
                                          "password" => user.foreign_password,
                                          "project_id" => cluster.team.project_id
                                        })
    end

    it "contains the cluster's team's billing account id" do
      expect(cluster.team.billing_acct_id).not_to be_nil
      expect(subject[:billing_account_id]).to eq cluster.team.billing_acct_id
    end

    it "contains the middleware url" do
      expect(cloud_service_config.user_handler_base_url).not_to be_nil
      expect(subject[:middleware_url]).to eq cloud_service_config.user_handler_base_url
    end
  end

  include_examples 'auth token header'
end
