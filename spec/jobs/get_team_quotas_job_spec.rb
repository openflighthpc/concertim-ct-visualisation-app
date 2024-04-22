require 'rails_helper'

RSpec.describe GetTeamQuotasJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:team) { create(:team, :with_openstack_details) }

  subject(:job_runner) {
    described_class::Runner.new(team: team, cloud_service_config: cloud_service_config, test_stubs: stubs)
  }

  let(:quotas_path) { "/team/#{team.project_id}/quotas" }
  let(:expected_url) {
    "#{cloud_service_config.user_handler_base_url}"
  }
  let(:expected_full_path) { "#{expected_url}#{quotas_path}" }

  describe "url" do
    subject { super().send(:url) }

    it "uses the correct ip and port" do
      expect(subject).to eq expected_url
    end
  end

  describe "path" do
    subject { super().send(:path) }

    it "uses the correct path" do
      expect(subject).to eq quotas_path
    end
  end

  describe "#perform" do
    context "when request is successful" do
      let(:quotas) do
        {
          "quotas" => {
            "backup_gigabytes" => 1024,
            "cores" => 21,
            "fixed_ips" => -1,
            "gigabytes" => 2048,
            "id" => "abc",
            "instances" => 10,
            "key_pairs" => 100,
            "network" => 100,
            "ram" => 419200
          },
          "success":true
        }
      end
      before(:each) do
        stubs.get(expected_full_path) { |env| [ 200, {}, quotas] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(cloud_service_config, team, test_stubs: stubs)
        expect(result).to be_success
      end

      it "contains the quotas, excluding id" do
        result = described_class.perform_now(cloud_service_config, team, test_stubs: stubs)
        expected = quotas["quotas"].dup
        expected.delete("id")
        expect(result.quotas).to eq expected
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.get(expected_full_path) { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, team, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, team, test_stubs: stubs)
        expect(result.error_message).to eq "Unable to retrieve team quotas: the server responded with status 404"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.get(expected_full_path) { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, team, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, team, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "Unable to retrieve team quotas: execution expired"
      end
    end
  end

  include_examples 'auth token header'
end
