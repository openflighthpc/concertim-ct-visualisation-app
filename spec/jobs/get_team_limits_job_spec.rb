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

RSpec.describe GetTeamLimitsJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:team) { create(:team, :with_openstack_details) }
  let(:user) { create(:user, :as_team_member, team: team) }

  subject(:job_runner) {
    described_class::Runner.new(team: team, user: user, cloud_service_config: cloud_service_config, test_stubs: stubs)
  }

  let(:limits_path) { "/team/limits" }
  let(:expected_url) {
    "#{cloud_service_config.user_handler_base_url}"
  }
  let(:expected_full_path) { "#{expected_url}#{limits_path}" }

  describe "url" do
    subject { super().send(:url) }

    it "uses the correct ip and port" do
      expect(subject).to eq expected_url
    end
  end

  describe "path" do
    subject { super().send(:path) }

    it "uses the correct path" do
      expect(subject).to eq limits_path
    end
  end

  describe "#perform" do
    context "when request is successful" do
      let(:limits) do
        {
          limits: {
            maxImageMeta: 128,
            maxPersonality: 5,
            maxPersonalitySize: 10240,
            maxSecurityGroupRules: -1,
            maxSecurityGroups: -1,
            maxServerGroupMembers: 10,
            maxServerGroups: 10,
            maxServerMeta: 128,
            maxTotalBackupGigabytes: 1024,
            maxTotalBackups: 10,
            maxTotalCores: 22,
            maxTotalFloatingIps: -1,
            maxTotalInstances: 10,
            maxTotalKeypairs: 100,
            maxTotalRAMSize: 419200,
            maxTotalSnapshots: 10,
            maxTotalVolumeGigabytes: 2048,
            maxTotalVolumes: 20,
            totalBackupGigabytesUsed: 0,
            totalBackupsUsed: 0,
            totalCoresUsed: 13,
            totalFloatingIpsUsed: 0,
            totalGigabytesUsed: 1136,
            totalInstancesUsed: 7,
            totalRAMUsed: 26624,
            totalSecurityGroupsUsed: 0,
            totalServerGroupsUsed: 0,
            totalSnapshotsUsed: 0,
            totalVolumesUsed: 8
          }
        }
      end
      before(:each) do
        stubs.get(expected_full_path) { |env| [ 200, {}, limits] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(cloud_service_config, team, user, test_stubs: stubs)
        expect(result).to be_success
      end

      it "contains the limits" do
        result = described_class.perform_now(cloud_service_config, team, user, test_stubs: stubs)
        expect(result.limits).to eq limits['limits']
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.get(expected_full_path) { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, team, user, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, team, user, test_stubs: stubs)
        expect(result.error_message).to eq "Unable to retrieve team limits: the server responded with status 404"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.get(expected_full_path) { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, team, user, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, team, user, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "Unable to retrieve team limits: execution expired"
      end
    end
  end

  include_examples 'auth token header'
end
