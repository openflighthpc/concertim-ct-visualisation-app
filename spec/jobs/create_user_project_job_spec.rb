require 'rails_helper'

RSpec.describe CreateUserProjectJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:user) { create(:user, cloud_user_id: Faker::Alphanumeric.alphanumeric(number: 10)) }

  subject(:job_runner) {
    CreateUserProjectJob::Runner.new(user: user, cloud_service_config: cloud_service_config, test_stubs: stubs)
  }

  describe "url" do
    let(:project_service_path) { "/project" }

    subject { super().send(:url) }

    it "uses the correct ip, port and path" do
      expect(subject).to eq "#{cloud_service_config.user_handler_base_url}#{project_service_path}"
    end
  end

  describe "body" do
    subject { super().send(:body).with_indifferent_access }

    it "contains the user's cloud user id" do
      expect(user.cloud_user_id).not_to be_nil
      expect(subject["primary_user_cloud_id"]).to eq user.cloud_user_id
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
    let(:project_service_path) { "/project" }
    context "when response does not contain expected fields" do
      let(:response_body) { {} }

      before(:each) do
        stubs.post(project_service_path) { |env| [ 201, {}, response_body ] }
      end

      it "raises ActiveModel::ValidationError" do
        expect { subject.call }.to raise_error ActiveModel::ValidationError
      end

      it "does not update the project_id" do
        expect { subject.call rescue nil }.not_to change(user, :project_id).from(nil)
      end
    end

    context "when response contains expected fields" do
      let(:project_id) { SecureRandom.uuid }
      let(:response_body) { {"project_id" => project_id} }

      before(:each) do
        stubs.post(project_service_path) { |env| [ 201, {}, response_body ] }
      end

      it "updates the user's project_id" do
        expect { subject.call }
          .to  change(user, :project_id).from(nil).to(project_id)
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

  describe "skipping users with a project" do
    let(:user) { create(:user, :with_openstack_details) }

    it "skips users which already have a project" do
      expect(described_class::Runner).not_to receive(:new)
      described_class.perform_now(user, cloud_service_config, test_stubs: stubs)
    end
  end

  include_examples 'auth token header'
end
