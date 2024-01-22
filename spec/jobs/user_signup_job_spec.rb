require 'rails_helper'

RSpec.describe UserSignupJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:user) { create(:user) }

  subject(:job_runner) {
    UserSignupJob::Runner.new(user: user, cloud_service_config: cloud_service_config, test_stubs: stubs)
  }

  describe "url" do
    let(:user_service_path) { "/create_user" }

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
    let(:user_service_path) { "/create_user" }
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
    end

    context "when response contains expected fields" do
      let(:cloud_user_id) { SecureRandom.uuid }
      let(:response_body) { { "user_id" => cloud_user_id } }

      before(:each) do
        stubs.post(user_service_path) { |env| [ 201, {}, response_body ] }
      end

      it "updates the user's cloud_user_id, project_id and billing_acct_id" do
        expect { subject.call }
          .to  change(user, :cloud_user_id).from(nil).to(cloud_user_id)
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
