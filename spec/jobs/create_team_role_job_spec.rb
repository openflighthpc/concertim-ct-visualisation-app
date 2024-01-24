require 'rails_helper'

RSpec.describe CreateTeamRoleJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:team) { create(:team, :with_openstack_details) }
  let(:user) { create(:user, :with_openstack_account) }
  let(:path) { "#{cloud_service_config.user_handler_base_url}/create_team_role" }
  let(:team_role) { build(:team_role, team: team,  user: user) }
  subject { CreateTeamRoleJob::Runner.new(team_role: team_role, cloud_service_config: cloud_service_config) }

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
      expect(subject.path).to eq "/create_team_role"
    end
  end

  describe "#perform" do
    context "when request is successful" do
      before(:each) do
        stubs.post(path) { |env| [ 200, {} ] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(team_role, cloud_service_config, test_stubs: stubs)
        expect(result).to be_success
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.post(path) { |env| [ 404, {}] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(team_role, cloud_service_config, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(team_role, cloud_service_config, test_stubs: stubs)
        expect(result.error_message).to eq "Unable to submit request: the server responded with status 404"
      end
    end

    context 'when request has json error response' do
      before(:each) do
        response_body = {"error" => "Conflict", "message" => "User already has that role"}.to_json
        stubs.post(path) { |env| [ 409, {"Content-type" => "application/json"}, response_body] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(team_role, cloud_service_config, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(team_role, cloud_service_config, test_stubs: stubs)
        expect(result.error_message).to eq "Unable to submit request: User already has that role"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.post(path) { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(team_role, cloud_service_config, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(team_role, cloud_service_config, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "Unable to submit request: execution expired"
      end
    end
  end

  describe "body" do
    subject { super().send(:body).with_indifferent_access }

    it 'contains team role details' do
      expect(subject[:team_role]).to eq({
                                         "role" => team_role.role,
                                         "project_id" => team_role.team.project_id,
                                         "user_id" => team_role.user.cloud_user_id
                                       })
    end

    it "contains the correct config and user details" do
      expect(subject[:cloud_env]).to eq({
                                          "auth_url" => cloud_service_config.internal_auth_url,
                                          "user_id" => cloud_service_config.admin_user_id,
                                          "password" => cloud_service_config.admin_foreign_password,
                                          "project_id" => cloud_service_config.admin_project_id,
                                        })
    end
  end

  include_examples 'auth token header'
end
