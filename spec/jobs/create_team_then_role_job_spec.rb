require 'rails_helper'

RSpec.describe CreateTeamThenRoleJob, type: :job do
  include ActiveJob::TestHelper
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:team) { create(:team) }
  let(:team_role) { create(:team_role, team: team) }

  subject(:job_runner) {
    CreateTeamThenRoleJob::Runner.new(team: team, team_role: team_role, cloud_service_config: cloud_service_config, test_stubs: stubs)
  }

  include_examples 'creating team job'

  describe "creating role on success" do
    let(:team_service_path) { "/team" }

    before(:each) do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    context "when team creation request succeeds" do
      let(:project_id) { SecureRandom.uuid }
      let(:billing_acct_id) { SecureRandom.uuid }
      let(:response_body) {
        {project_id: project_id, billing_acct_id: billing_acct_id}
          .stringify_keys
      }

      before(:each) do
        stubs.post(team_service_path) { |env| [ 201, {}, response_body ] }
      end

      it "enqueues job to create role" do
        subject.call
        expect(CreateTeamRoleJob).to have_been_enqueued.with(team_role, cloud_service_config)
      end
    end

    context "when team creation request fails" do
      let(:response_body) { {} }

      before(:each) do
        stubs.post(team_service_path) { |env| [ 201, {}, response_body ] }
      end

      it "does not enqueue role creation" do
        subject.call rescue nil
        expect(CreateTeamRoleJob).not_to have_been_enqueued
      end
    end
  end
end
