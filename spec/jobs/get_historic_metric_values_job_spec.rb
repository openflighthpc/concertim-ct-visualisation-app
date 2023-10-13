require 'rails_helper'

RSpec.describe GetHistoricMetricValuesJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:device_id) { 1 }
  let(:start_date) { Date.parse("2023-01-01") }
  let(:end_date) { Date.parse("2023-01-10") }
  let(:start_time) { start_date.beginning_of_day.utc.to_i }
  let(:end_time) { end_date.end_of_day.utc.to_i }

  let(:path) { "http://localhost:3000/device/#{device_id}/metrics/#{ERB::Util.url_encode(metric_name)}/historic/#{start_time}/#{end_time}" }
  let(:metric_name) { "power level" }
  subject do
    GetHistoricMetricValuesJob::Runner.new(metric_name: metric_name, device_id: 1,
                                           start_date: start_date, end_date: end_date, cloud_service_config: nil)
  end

  describe "url" do
    before(:each) do
      class << subject
        public :connection
        public :path
      end
    end

    it "uses the configured ip and port" do
      expect(subject.connection.url_prefix.to_s).to eq "http://localhost:3000"
    end

    it "uses the correct path" do
      expect(subject.path).to eq "/device/1/metrics/power%20level/historic/1672531200/1673395199"
    end
  end

  describe "#perform" do
    context "when request is successful" do
      before(:each) do
        puts(path)
        stubs.get(path) { |env| [ 200, {}, metric_values.map(&:stringify_keys)] }
      end

      let(:metric_values) {
        [
          {timestamp: 1672531200, "value" => 32},
          {timestamp: 1672531205, "value" => 64},
        ]
      }

      let(:expected_metric_values) {
        klass = GetHistoricMetricValuesJob::Result::MetricValue
        [klass.new(timestamp: 1672531200, value: 45.5)]
      }

      it "returns a successful result" do
        result = described_class.perform_now(metric_name: metric_name, device_id: device_id,
                                              start_date: start_date, end_date: end_date,
                                              test_stubs: stubs)
        expect(result).to be_success
      end

      it "makes the metrics available" do
        result = described_class.perform_now(metric_name: metric_name, device_id: device_id,
                                             start_date: start_date, end_date: end_date,
                                             test_stubs: stubs)
        expect(result.metric_values).to eq expected_metric_values
      end
    end

    context "when no data" do
      before(:each) do
        stubs.get(path) { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(metric_name: metric_name, device_id: device_id,
                                             start_date: start_date, end_date: end_date,
                                             test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error message" do
        result = described_class.perform_now(metric_name: metric_name, device_id: device_id,
                                             start_date: start_date, end_date: end_date,
                                             test_stubs: stubs)
        expect(result.error_message).to eq "Unable to fetch metric values: the server responded with status 404"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.get(path) { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(metric_name: metric_name, device_id: device_id,
                                             start_date: start_date, end_date: end_date,
                                             test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(metric_name: metric_name, device_id: device_id,
                                             start_date: start_date, end_date: end_date,
                                             test_stubs: stubs)
        expect(result.error_message).to eq "Unable to fetch metric values: execution expired"
      end
    end
  end
end
