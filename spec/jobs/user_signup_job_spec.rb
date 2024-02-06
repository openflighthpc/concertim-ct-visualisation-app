require 'rails_helper'

RSpec.describe UserSignupJob, type: :job do
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

    context "when the user has a billing id" do
      let(:user) { create(:user, billing_acct_id: Faker::Internet.uuid) }

      it "contains the user's billing id" do
        expect(user.billing_acct_id).not_to be_nil
        expect(subject["billing_acct_id"]).to eq user.billing_acct_id
      end
    end

    context "when the user does not have a billing id" do
      it "does not contain the user's billing id" do
        expect(user.billing_acct_id).to be_nil
        expect(subject).not_to have_key "billing_acct_id"
        expect(subject).not_to have_key :billing_acct_id
      end
    end

    context "when the user has a cloud user id" do
      let(:user) { create(:user, cloud_user_id: Faker::Internet.uuid) }

      it "contains the user's cloud user id" do
        expect(user.cloud_user_id).not_to be_nil
        expect(subject["cloud_id"]).to eq user.cloud_user_id
      end
    end

    context "when the user does not have a cloud user id" do
      it "does not contain the user's cloud user id" do
        expect(user.cloud_user_id).to be_nil
        expect(subject).not_to have_key "cloud_id"
        expect(subject).not_to have_key :cloud_id
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

      it "does not update the billing_id" do
        expect { subject.call rescue nil }.not_to change(user, :billing_acct_id).from(nil)
      end
    end

    context "when response contains expected fields" do
      let(:cloud_user_id) { SecureRandom.uuid }
      let(:billing_acct_id) { SecureRandom.uuid }
      let(:response_body) {
        {cloud_id: cloud_user_id, billing_acct_id: billing_acct_id}
          .stringify_keys
      }

      before(:each) do
        stubs.post(user_service_path) { |env| [ 201, {}, response_body ] }
      end

      it "updates the user's cloud_user_id and billing_acct_id" do
        expect { subject.call }
          .to  change(user, :cloud_user_id).from(nil).to(cloud_user_id)
          .and change(user, :billing_acct_id).from(nil).to(billing_acct_id)
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
