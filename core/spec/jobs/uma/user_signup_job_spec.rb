require 'rails_helper'

RSpec.describe Uma::UserSignupJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:config) { create(:fleece_config) }
  let(:user) { create(:user) }

  subject(:job_runner) {
    Uma::UserSignupJob::Runner.new(user: user, fleece_config: config, test_stubs: stubs)
  }

  describe "url" do
    let(:user_service_path) { "/create_user_project" }

    subject { super().send(:url) }

    it "uses the correct ip, port and path" do
      expect(subject).to eq "#{config.host_url[0...-5]}:#{config.user_handler_port}#{user_service_path}"
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

    context "when the user has a cloud user id" do
      let(:user) { create(:user, cloud_user_id: Faker::Internet.uuid) }

      it "contains the user's cloud user id" do
        expect(user.cloud_user_id).not_to be_nil
        expect(subject["cloud_user_id"]).to eq user.cloud_user_id
      end
    end

    context "when the user does not have a cloud user id" do
      it "does not contain the user's cloud user id" do
        expect(user.cloud_user_id).to be_nil
        expect(subject).not_to have_key "cloud_user_id"
        expect(subject).not_to have_key :cloud_user_id
      end
    end

    it "contains the correct cloud environment config" do
      expect(subject[:cloud_env]).to eq({
        "auth_url" => config.internal_auth_url,
        "user_id" => config.admin_user_id,
        "password" => config.admin_foreign_password,
        "project_id" => config.admin_project_id
      })
    end
  end

  describe "updating the user's details from the response" do
    let(:user_service_path) { "/create_user_project" }
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

      it "does not update the project_id" do
        expect { subject.call rescue nil }.not_to change(user, :project_id).from(nil)
      end
    end

    context "when response contains expected fields" do
      let(:cloud_user_id) { SecureRandom.uuid }
      let(:project_id) { SecureRandom.uuid }
      let(:response_body) { {user_id: cloud_user_id, project_id: project_id}.stringify_keys }

      before(:each) do
        stubs.post(user_service_path) { |env| [ 201, {}, response_body ] }
      end

      it "updates the user's cloud_user_id and project_id" do
        expect { subject.call }
          .to  change(user, :cloud_user_id).from(nil).to(cloud_user_id)
          .and change(user, :project_id).from(nil).to(project_id)
      end
    end
  end
end
