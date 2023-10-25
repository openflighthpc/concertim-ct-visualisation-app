require 'rails_helper'

RSpec.describe GetUniqueMetricsJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:path) { "http://localhost:3000/metrics/unique" }
  subject { GetUniqueMetricsJob::Runner.new(cloud_service_config: nil) }

  describe "url" do
    before(:each) do
      class << subject
        public :connection
        public :path
      end
    end

    it "uses the configured ip and port" do
      expect(subject.connection.url_prefix.to_s).to eq Rails.application.config.metric_daemon_url
    end

    it "uses a hard-coded path" do
      expect(subject.path).to eq "/metrics/unique"
    end
  end

  describe "#perform" do
    context "when request is successful" do
      before(:each) do
        stubs.get(path) { |env| [ 200, {}, metrics.map(&:stringify_keys)] }
      end

      let(:metrics) {
        [
          {id: "caffeine.consumption", name: "caffeine.consumption", units: "cups", nature: "volatile", min: 0, max: 4},
          {id: "caffeine.level", name: "caffeine.level", units: "", nature: "volatile", min: 32, max: 64},
          {id: "power.level", name: "power.level", nature: "volatile", min: 0, max: 8999},
        ]
      }

      let(:expected_metrics) {
        metrics.map { |m| GetUniqueMetricsJob::Result::MetricType.new(**m) }
      }

      it "returns a successful result" do
        result = described_class.perform_now(test_stubs: stubs)
        expect(result).to be_success
      end

      it "makes the metrics available" do
        result = described_class.perform_now(test_stubs: stubs)
        expect(result.metrics).to eq expected_metrics
      end
    end

    context "when request has bad format" do
      before(:each) do
        stubs.get(path) { |env| [ 200, {}, bad_metrics.stringify_keys] }
      end

      # A single metric isn't the right format.  It should be an array of metrics.
      let(:bad_metrics) {
        {id: "power.level", name: "power.level", nature: "volatile", min: 0, max: 8999}
      }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(test_stubs: stubs)
        expect(result.error_message).to eq "Parsing unique metrics failed: no implicit conversion of String into Integer"
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.get(path) { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(test_stubs: stubs)
        expect(result.error_message).to eq "Unable to fetch unique metrics: the server responded with status 404"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.get(path) { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "Unable to fetch unique metrics: execution expired"
      end
    end
  end
end
