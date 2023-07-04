require 'rails_helper'

RSpec.describe Uma::UserSignupJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:config) { create(:fleece_config) }
  let(:user) { create(:user) }

  subject(:job_runner) {
    Uma::UserSignupJob::Runner.new(user: user, fleece_config: config)
  }

  describe "url" do
    let(:user_service_path) { "/create-user-project/" }

    subject { super().send(:url) }

    it "uses the correct ip, port and path" do
      expect(subject).to eq "http://#{config.host_ip}:#{config.user_handler_port}#{user_service_path}"
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

    context "when the user has a project id" do
      let(:user) { create(:user, project_id: Faker::Internet.uuid) }

      it "contains the user's project id" do
        expect(user.project_id).not_to be_nil
        expect(subject["project_id"]).to eq user.project_id
      end
    end

    context "when the user does not have a project id" do
      it "does not contain the user's project id" do
        expect(user.project_id).to be_nil
        expect(subject).not_to have_key "project_id"
        expect(subject).not_to have_key :project_id
      end
    end

    it "contains the correct cloud environment config" do
      expect(subject[:cloud_env]).to eq({
        "auth_url" => config.auth_url,
        "username" => "admin",
        "password" => config.password,
        "project_name" => config.project_name,
        "user_domain_name" => config.domain_name,
        "project_domain_name" => config.domain_name,
      })
    end
  end
end
