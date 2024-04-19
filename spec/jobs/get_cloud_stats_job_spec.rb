require 'rails_helper'

RSpec.describe GetCloudStatsJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }

  subject(:job_runner) {
    described_class::Runner.new(cloud_service_config: cloud_service_config, test_stubs: stubs)
  }

  let(:stats_path) { "/statistics" }
  let(:expected_url) {
    "#{cloud_service_config.user_handler_base_url}"
  }
  let(:expected_full_path) { "#{expected_url}#{stats_path}" }

  describe "url" do
    subject { super().send(:url) }

    it "uses the correct ip and port" do
      expect(subject).to eq expected_url
    end
  end

  describe "path" do
    subject { super().send(:path) }

    it "uses the correct path" do
      expect(subject).to eq stats_path
    end
  end

  describe "#perform" do
    context "when request is successful" do
      let(:stats) do
        {
          "used_vcpus" => 10,
          "total_vcpus" => 20,
          "used_disk_space" => 10,
          "total_disk_space" => 20,
          "used_ram" => 1,
          "total_ram" => 2,
          "running_vms" => 3
        }
      end
      before(:each) do
        stubs.get(expected_full_path) { |env| [ 200, {}, {"stats" => stats}] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(cloud_service_config, test_stubs: stubs)
        expect(result).to be_success
      end

      it "contains the stats" do
        result = described_class.perform_now(cloud_service_config, test_stubs: stubs)
        expected = {
          "Allocated / Total VCPUs" => "10 / 20",
          "Allocated / Total Disk Space" => "10 / 20GB",
          "Allocated / Total RAM" => "1 / 2GB",
          "Virtual Machines" => "3"
        }
        expect(result.stats).to eq expected
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.get(expected_full_path) { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, test_stubs: stubs)
        expect(result.error_message).to eq "Unable to retrieve cloud statistics: the server responded with status 404"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.get(expected_full_path) { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "Unable to retrieve cloud statistics: execution expired"
      end
    end
  end

  include_examples 'auth token header'
end
