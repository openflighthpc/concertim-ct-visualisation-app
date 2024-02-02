require 'rails_helper'

RSpec.describe UserUpdateJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let!(:user) { create(:user, :with_openstack_account) }
  let(:changes) { {} }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:update_users_path) { "/change_user_details" }
  let(:expected_url) {
    "#{cloud_service_config.user_handler_base_url}#{update_users_path}"
  }

  subject { UserUpdateJob::Runner.new(cloud_service_config: cloud_service_config, user: user, changes: changes) }

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

    it "contains the user's cloud env id" do
      expect(subject[:user_info]).to be_a Hash
      expect(subject[:user_info][:cloud_user_id]).to eq user.cloud_user_id
    end

    [
      {name: "when password is updated", changes: {email: false, password: true}, expectations: [:password]},
      {name: "when email is updated", changes: {email: true, password: false}, expectations: [:email]},
      {name: "when both email and password are updated", changes: {email: true, password: true}, expectations: [:email, :password]},
    ].each do |tt|
        context tt[:name] do
          let(:changes) { tt[:changes] }

          it "contains the expected updated details" do
            expect(subject[:user_info]).to be_a Hash
            expect(subject[:user_info][:new_data]).to be_a Hash
            tt[:expectations].each do |ex|
              expect(subject[:user_info][:new_data][ex]).to eq user.send(ex)
            end
          end
        end
      end
  end

  describe "#perform" do
    include ActiveJob::TestHelper

    context "when user does not have openstack" do
      let!(:user) { create(:user) }

      it "does not make a request to the middleware" do
        expect(described_class::Runner).not_to receive(:new)
        described_class.perform_now(user, changes, cloud_service_config, test_stubs: stubs)
      end

      it "does not update the user" do
        expect {
          described_class.perform_now(user, changes, cloud_service_config)
        }.not_to change(user, :updated_at)
      end
    end

    context "when user has openstack details" do

      shared_examples "makes a request to the middleware" do
        it "makes a request to the middleware" do
          runner = described_class::Runner.new(user: user, changes: changes, cloud_service_config: cloud_service_config)
          expect(described_class::Runner).to receive(:new)
            .with(hash_including(user: user, changes: changes, cloud_service_config: cloud_service_config))
            .and_return(runner)
          allow(runner).to receive(:call).and_call_original
          described_class.perform_now(user, changes, cloud_service_config)
          expect(runner).to have_received(:call)
        end
      end

      context "when the request is successful" do
        before(:each) do
          stubs.post(expected_url) { |env| [ 204, {}, "No Content"] }
          allow_any_instance_of(described_class::Runner).to receive(:test_stubs).and_return(stubs)
        end

        include_examples "makes a request to the middleware"

        it "updates the user" do
          expect {
            described_class.perform_now(user, changes, cloud_service_config)
          }.to change(user, :foreign_password)
        end
      end

      context "when the request is unsuccessful" do
        before(:each) do
          stubs.post(expected_url) { |env| [ 500, {}, {"error" => "Some error message"}] }
          allow_any_instance_of(described_class::Runner).to receive(:test_stubs).and_return(stubs)
        end

        include_examples "makes a request to the middleware"

        it "does not update the user" do
          expect {
            described_class.perform_now(user, changes, cloud_service_config)
          }.not_to change(user, :updated_at)
        end

        it "reschedules the job" do
          perform_enqueued_jobs do
            begin
              described_class.perform_later(user, changes, cloud_service_config)
            rescue ::Faraday::Error
              # We expect a ::Faraday::Error to be raised here, when the last retried job fails.
            end
          end
          expect(UserUpdateJob::RETRY_ATTEMPTS).to be > 1
          expect(UserUpdateJob).to have_been_performed.exactly(UserUpdateJob::RETRY_ATTEMPTS)
        end
      end
    end
  end
end
