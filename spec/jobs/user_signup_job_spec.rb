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

RSpec.describe UserSignupJob, type: :job do
  include ActiveJob::TestHelper
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:user) { create(:user) }

  subject(:job_runner) {
    UserSignupJob::Runner.new(user: user, cloud_service_config: cloud_service_config, test_stubs: stubs)
  }

  describe "url" do
    let(:user_service_path) { "/user" }

    subject { super().send(:url) }

    it "uses the correct ip, port and path" do
      expect(subject).to eq "#{cloud_service_config.user_handler_base_url}#{user_service_path}"
    end
  end

  describe "body" do
    subject { super().send(:body).with_indifferent_access }

    it "contains the user's username" do
      expect(subject["username"]).to eq user.login
    end

    it "contains the user's unencrypted password" do
      expect(subject["password"]).to eq user.password
    end

    it "contains the user's email address" do
      expect(subject["email"]).to eq user.email
    end

    it "contains the correct cloud environment config" do
      expect(subject[:cloud_env]).to eq({
        "auth_url" => cloud_service_config.internal_auth_url,
        "user_id" => cloud_service_config.admin_user_id,
        "password" => cloud_service_config.admin_foreign_password,
        "project_id" => cloud_service_config.admin_project_id
      })
    end
  end

  describe "updating the user's details from the response" do
    let(:user_service_path) { "/user" }
    context "when response does not contain expected fields" do
      let(:response_body) { {} }

      before(:each) do
        stubs.post(user_service_path) { |env| [ 201, {}, response_body ] }
      end

      it "raises ActiveModel::ValidationError" do
        expect { subject.call }.to raise_error ActiveModel::ValidationError
      end

      it "does not update the cloud_user_id" do
        expect { subject.call rescue nil }.not_to change(user, :cloud_user_id).from(nil)
      end

      it "does not enqueue user team creation" do
        clear_enqueued_jobs
        clear_performed_jobs

        subject.call rescue nil
        expect(CreateSingleUserTeamJob).not_to have_been_enqueued
      end
    end

    context "when response contains expected fields" do
      let(:cloud_user_id) { SecureRandom.uuid }
      let(:response_body) { { "user_cloud_id" => cloud_user_id } }

      before(:each) do
        stubs.post(user_service_path) { |env| [ 201, {}, response_body ] }
      end

      it "updates the user's cloud_user_id, project_id and billing_acct_id" do
        expect { subject.call }
          .to  change(user, :cloud_user_id).from(nil).to(cloud_user_id)
      end

      it "enqueues user team creation" do
        clear_enqueued_jobs
        clear_performed_jobs

        subject.call
        expect(CreateSingleUserTeamJob).to have_been_enqueued.with(user, cloud_service_config)
      end
    end
  end

  describe "skipping deleted users" do
    let(:user) { create(:user, deleted_at: Time.current) }

    it "skips users which have already been deleted" do
      expect(described_class::Runner).not_to receive(:new)
      described_class.perform_now(user, cloud_service_config, test_stubs: stubs)
    end
  end

  include_examples 'auth token header'
end
