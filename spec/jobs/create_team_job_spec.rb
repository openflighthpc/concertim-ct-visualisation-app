require 'rails_helper'

RSpec.describe CreateTeamJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:team) { create(:team) }

  subject(:job_runner) {
    CreateTeamJob::Runner.new(team: team, cloud_service_config: cloud_service_config, test_stubs: stubs)
  }

  describe "url" do
    let(:team_service_path) { "/create_team" }

    subject { super().send(:url) }

    it "uses the correct ip, port and path" do
      expect(subject).to eq "#{cloud_service_config.user_handler_base_url}#{team_service_path}"
    end
  end

  describe "body" do
    subject { super().send(:body).with_indifferent_access }

    it "contains the team's name" do
      expect(subject["name"]).to eq team.name
    end

    context "when the team has a project id" do
      let(:team) { create(:team, project_id: Faker::Internet.uuid) }

      it "contains the team's project id" do
        expect(team.project_id).not_to be_nil
        expect(subject["project_id"]).to eq team.project_id
      end
    end

    context "when the team does not have a project id" do
      it "does not contain the team's project id" do
        expect(team.project_id).to be_nil
        expect(subject).not_to have_key "project_id"
        expect(subject).not_to have_key :project_id
      end
    end

    context "when the team has a billing account id" do
      let(:team) { create(:team, billing_acct_id: Faker::Internet.uuid) }

      it "contains the team's billing account id" do
        expect(team.billing_acct_id).not_to be_nil
        expect(subject["billing_account_id"]).to eq team.billing_acct_id
      end
    end

    context "when the team does not have a billing account id" do
      it "does not contain the team's billing account id" do
        expect(team.billing_acct_id).to be_nil
        expect(subject).not_to have_key "billing_account_id"
        expect(subject).not_to have_key :billing_account_id
      end
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

  describe "updating the team's details from the response" do
    let(:team_service_path) { "/create_team" }
    context "when response does not contain expected fields" do
      let(:response_body) { {} }

      before(:each) do
        stubs.post(team_service_path) { |env| [ 201, {}, response_body ] }
      end

      it "raises ActiveModel::ValidationError" do
        expect { subject.call }.to raise_error ActiveModel::ValidationError
      end

      it "does not update the project_id" do
        expect { subject.call rescue nil }.not_to change(team, :project_id).from(nil)
      end

      it "does not update the billing_acct_id" do
        expect { subject.call rescue nil }.not_to change(team, :billing_acct_id).from(nil)
      end
    end

    context "when response contains expected fields" do
      let(:project_id) { SecureRandom.uuid }
      let(:billing_acct_id) { SecureRandom.uuid }
      let(:response_body) {
        {project_id: project_id, billing_account_id: billing_acct_id}
          .stringify_keys
      }

      before(:each) do
        stubs.post(team_service_path) { |env| [ 201, {}, response_body ] }
      end

      it "updates the team's project_id and billing_acct_id" do
        expect { subject.call }
          .to  change(team, :project_id).from(nil).to(project_id)
                                        .and change(team, :billing_acct_id).from(nil).to(billing_acct_id)
      end
    end
  end

  describe "skipping deleted teams" do
    let(:team) { create(:team, deleted_at: Time.current) }

    it "skips teams which have already been deleted" do
      expect(described_class::Runner).not_to receive(:new)
      described_class.perform_now(team, cloud_service_config, test_stubs: stubs)
    end
  end

  include_examples 'auth token header'
end
