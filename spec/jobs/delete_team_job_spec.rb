require 'rails_helper'

RSpec.describe DeleteTeamJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let!(:team) { create(:team, :with_openstack_details) }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:delete_team_path) { "/delete_team" }
  let(:expected_url) {
    "#{cloud_service_config.user_handler_base_url}#{delete_team_path}"
  }

  subject { DeleteTeamJob::Runner.new(cloud_service_config: cloud_service_config, team: team) }

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

    it "contains the team's cloud env and billing ids" do
      expect(subject[:team_info]).to be_a Hash
      expect(subject[:team_info][:project_id]).to eq team.project_id
      expect(subject[:team_info][:billing_acct_id]).to eq team.billing_acct_id
    end
  end

  describe "#perform" do
    include ActiveJob::TestHelper

    context "when team does not have openstack" do
      let!(:team) { create(:team) }

      it "does not make a request to the middleware" do
        expect(described_class::Runner).not_to receive(:new)
        described_class.perform_now(team, cloud_service_config, test_stubs: stubs)
      end

      it "destroys the team" do
        expect {
          described_class.perform_now(team, cloud_service_config, test_stubs: stubs)
        }.to change(Team, :count).by(-1)
      end
    end

    context "when team has openstack details" do

      shared_examples "makes a request to the middleware" do
        it "makes a request to the middleware" do
          runner = described_class::Runner.new(team: team, cloud_service_config: cloud_service_config)
          expect(described_class::Runner).to receive(:new)
                                               .with(hash_including(team: team, cloud_service_config: cloud_service_config))
                                               .and_return(runner)
          allow(runner).to receive(:call).and_call_original
          described_class.perform_now(team, cloud_service_config)
          expect(runner).to have_received(:call)
        end
      end

      context "when the request is successful" do
        before(:each) do
          stubs.delete(expected_url) { |env| [ 204, {}, "No Content"] }
          allow_any_instance_of(described_class::Runner).to receive(:test_stubs).and_return(stubs)
        end

        include_examples "makes a request to the middleware"

        it "destroys the team" do
          expect {
            described_class.perform_now(team, cloud_service_config, test_stubs: stubs)
          }.to change(Team, :count).by(-1)
        end
      end

      context "when the request is unsuccessful" do
        before(:each) do
          stubs.delete(expected_url) { |env| [ 500, {}, {"error" => "Some error message"}] }
          allow_any_instance_of(described_class::Runner).to receive(:test_stubs).and_return(stubs)
        end

        include_examples "makes a request to the middleware"

        it "does not destroy the team" do
          expect {
            described_class.perform_now(team, cloud_service_config)
          }.not_to change(Team, :count)
        end

        it "reschedules the job" do
          perform_enqueued_jobs do
            begin
              described_class.perform_later(team, cloud_service_config)
            rescue ::Faraday::Error
              # We expect a ::Faraday::Error to be raised here, when the last retried job fails.
            end
          end
          expect(DeleteTeamJob::RETRY_ATTEMPTS).to be > 1
          expect(DeleteTeamJob).to have_been_performed.exactly(DeleteTeamJob::RETRY_ATTEMPTS)
        end
      end
    end
  end

  include_examples 'auth token header'
end
