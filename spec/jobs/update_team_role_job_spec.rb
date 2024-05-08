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

RSpec.describe UpdateTeamRoleJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let!(:team_role) { create(:team_role, role: "member") }
  let(:new_role) { "admin" }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:update_roles_path) { "/team_role" }
  let(:expected_url) {
    "#{cloud_service_config.user_handler_base_url}#{update_roles_path}"
  }

  subject { UpdateTeamRoleJob::Runner.new(cloud_service_config: cloud_service_config, team_role: team_role, new_role: new_role) }

  describe "url" do
    subject { super().send(:url) }

    it "uses the correct ip, port and path" do
      expect(subject).to eq expected_url
    end
  end

  describe "body" do
    subject { super().send(:body).with_indifferent_access }

    it "contains the admin's cloud env credentials" do
      expect(subject[:cloud_env]).to eq({
                                          "auth_url" => cloud_service_config.internal_auth_url,
                                          "user_id" => cloud_service_config.admin_user_id,
                                          "password" => cloud_service_config.admin_foreign_password,
                                          "project_id" => cloud_service_config.admin_project_id,
                                        })
    end

    it "contains the user's cloud env and billing ids" do
      expect(subject[:team_role]).to be_a Hash
      expect(subject[:team_role][:user_id]).to eq team_role.user.cloud_user_id
      expect(subject[:team_role][:project_id]).to eq team_role.team.project_id
    end
  end

  describe "#perform" do
    include ActiveJob::TestHelper

    shared_examples "makes a request to the middleware" do
      it "makes a request to the middleware" do
        runner = described_class::Runner.new(team_role: team_role, new_role: new_role, cloud_service_config: cloud_service_config)
        expect(described_class::Runner).to receive(:new)
                                             .with(hash_including(team_role: team_role, new_role: new_role, cloud_service_config: cloud_service_config))
                                             .and_return(runner)
        allow(runner).to receive(:call).and_call_original
        described_class.perform_now(team_role, new_role, cloud_service_config)
        expect(runner).to have_received(:call)
      end
    end

    context "when the request is successful" do
      before(:each) do
        stubs.patch(expected_url) { |env| [ 204, {}, "No Content"] }
        allow_any_instance_of(described_class::Runner).to receive(:test_stubs).and_return(stubs)
      end

      include_examples "makes a request to the middleware"

      it "updates role" do
        expect {
          described_class.perform_now(team_role, new_role, cloud_service_config, test_stubs: stubs)
        }.to change(team_role, :role)
      end
    end

    context "when the request is unsuccessful" do
      before(:each) do
        stubs.patch(expected_url) { |env| [ 500, {}, {"error" => "Some error message"}] }
        allow_any_instance_of(described_class::Runner).to receive(:test_stubs).and_return(stubs)
      end

      include_examples "makes a request to the middleware"

      it "does not change the role" do
        expect {
          described_class.perform_now(team_role, new_role ,cloud_service_config)
        }.not_to change(team_role, :role)
      end
    end
  end

  include_examples 'auth token header'
end
