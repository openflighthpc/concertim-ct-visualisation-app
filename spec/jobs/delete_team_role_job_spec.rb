require 'rails_helper'

RSpec.describe DeleteTeamRoleJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let!(:team_role) { create(:team_role, role: "member") }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:delete_team_role_path) { "/delete_team_role" }
  let(:path) { "#{cloud_service_config.user_handler_base_url}/delete_team_role" }

  subject { DeleteTeamRoleJob::Runner.new(cloud_service_config: cloud_service_config, team_role: team_role) }

  describe "url" do
    before(:each) do
      class << subject
        public :connection
        public :path
      end
    end

    it "uses the ip and port given in the config" do
      expect(subject.connection.url_prefix.to_s).to eq "#{cloud_service_config.user_handler_base_url}/"
    end

    it "uses a hard-coded path" do
      expect(subject.path).to eq "/delete_team_role"
    end
  end

  describe "path" do
    subject { super().send(:path) }

    it "uses the path" do
      expect(subject).to eq delete_team_role_path
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

    it "contains the team role's details" do
      expect(subject[:team_role]).to be_a Hash
      expect(subject[:team_role][:user_id]).to eq team_role.user.cloud_user_id
      expect(subject[:team_role][:project_id]).to eq team_role.team.project_id
      expect(subject[:team_role][:role]).to eq team_role.role
    end
  end

  describe "#perform" do
    include ActiveJob::TestHelper

    shared_examples "makes a request to the middleware" do
      it "makes a request to the middleware" do
        runner = described_class::Runner.new(team_role: team_role, cloud_service_config: cloud_service_config)
        expect(described_class::Runner).to receive(:new)
                                             .with(hash_including(team_role: team_role, cloud_service_config: cloud_service_config))
                                             .and_return(runner)
        allow(runner).to receive(:call).and_call_original
        described_class.perform_now(team_role, cloud_service_config)
        expect(runner).to have_received(:call)
      end
    end

    context "when the request is successful" do
      before(:each) do
        stubs.delete(path) { |env| [ 204, {}, "No Content"] }
        allow_any_instance_of(described_class::Runner).to receive(:test_stubs).and_return(stubs)
      end

      include_examples "makes a request to the middleware"

      it "deletes role" do
        expect {
          described_class.perform_now(team_role, cloud_service_config, test_stubs: stubs)
        }.to change(TeamRole, :count).by(-1)
      end
    end

    context "when the request is unsuccessful" do
      before(:each) do
        stubs.delete(path) { |env| [ 500, {}, {"error" => "Some error message"}] }
        allow_any_instance_of(described_class::Runner).to receive(:test_stubs).and_return(stubs)
      end

      include_examples "makes a request to the middleware"

      it "does not change the role" do
        expect {
          described_class.perform_now(team_role,cloud_service_config)
        }.not_to change(TeamRole, :count)
      end
    end
  end

  include_examples 'auth token header'
end
