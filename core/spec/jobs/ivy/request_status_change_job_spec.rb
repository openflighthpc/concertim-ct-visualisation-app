require 'rails_helper'

RSpec.describe Ivy::RequestStatusChangeJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:config) { create(:fleece_config, admin_project_id: Faker::Internet.uuid, admin_user_id: Faker::Internet.uuid) }
  let(:customer_user) { create(:user, project_id: Faker::Internet.uuid, cloud_user_id: Faker::Internet.uuid) }
  let(:admin) { create(:user, :admin) }
  let(:user) { customer_user }
  let(:device) { create(:device, chassis: chassis, status: "ACTIVE") }
  let(:chassis) { create(:chassis, location: location, template: device_template) }
  let(:location) { create(:location, rack: rack) }
  let(:rack) { create(:rack, user: user, template: rack_template, status: "ACTIVE") }
  let(:device_template) { create(:template, :device_template) }
  let(:rack_template) { create(:template, :rack_template) }
  let(:action) { "destroy" }
  let(:type) { "devices" }
  let(:target) { device }
  let(:user_service_path) { "/update_status" }

  subject(:job_runner) {
    Ivy::RequestStatusChangeJob::Runner.new(user: user, type: type, target: target, action: action, fleece_config: config, test_stubs: stubs)
  }

  describe "url" do
    subject { super().send(:url) }

    shared_examples 'correct full url' do
      it "uses the correct ip, port and path" do
        expect(subject).to eq "#{config.host_url[0...-5]}:#{config.user_handler_port}#{user_service_path}/#{type}/#{target.openstack_id}"
      end
    end

    context 'device' do
      let(:target) { device }
      let(:type) { "devices" }

      include_examples 'correct full url'
    end

    context 'rack' do
      let(:target) { rack }
      let(:type) { "racks" }

      include_examples 'correct full url'
    end
  end

  describe "body" do
    subject { super().send(:body).with_indifferent_access }

    context 'admin' do
      let(:user) { admin }
      it "contains the admin credentials from config" do
        expect(subject[:cloud_env]).to eq({
                                            "auth_url" => config.internal_auth_url,
                                            "user_id" => config.admin_user_id.gsub("-", ""),
                                            "password" => config.admin_password,
                                            "project_id" => config.admin_project_id
                                          })
      end
    end

    context 'non admin' do
      let(:user) { customer_user }
      it "contains the user's credentials" do
        expect(subject[:cloud_env]).to eq({
                                            "auth_url" => config.internal_auth_url,
                                            "user_id" => user.cloud_user_id.gsub("-", ""),
                                            "password" => user.fixme_encrypt_this_already_plaintext_password,
                                            "project_id" => user.project_id
                                          })
      end
    end

    it "contains the required action" do
      expect(subject[:action]).to eq action
    end
  end

  describe "#perform" do
    let(:path) { "#{config.host_url[0...-5]}:#{config.user_handler_port}#{user_service_path}/#{type}/#{target.openstack_id}" }

    context 'given an invalid actions' do
      let(:target) { device }
      let(:action) { "deep fry" }

      it "returns a failure" do
        result = described_class.perform_now(target, type, action, config, user, test_stubs: stubs)
        expect(result).not_to be_success
        expect(result.error_message).to eq "#{action} is not a valid action for #{target.name}"
      end
    end

    context "when request is successful" do
      before(:each) do
        stubs.post(path) { |env| [ 200, {}, ""] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(target, type, action, config, user, test_stubs: stubs)
        expect(result).to be_success
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.post(path) { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(target, type, action, config, user, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(target, type, action, config, user, test_stubs: stubs)
        expect(result.error_message).to eq "Unable to submit request: the server responded with status 404"
      end
    end

    context "when request has error detail" do
      before(:each) do
        stubs.post(path) { |env| [ 400, {'content-type' => 'application/json'}, {'error' => "Gremlins", 'message' => "Insufficient mana"}.to_json] }
      end

      it "returns an unsuccessful result" do
        result = subject.call
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = subject.call
        expect(result.error_message).to eq "Unable to submit request: Insufficient mana"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.post(path) { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(target, type, action, config, user, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(target, type, action, config, user, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "Unable to submit request: execution expired"
      end
    end
  end
end
