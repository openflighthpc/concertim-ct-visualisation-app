require 'rails_helper'

RSpec.describe "Api::V1::MetricsController", type: :request do
  let!(:rack_template) { create(:template, :rack_template) }
  let!(:rack) { create(:rack, user: rack_owner, template: rack_template) }
  let(:chassis) { create(:chassis, template: device_template, location: location) }
  let(:location) { create(:location, rack: rack) }
  let(:device_template) { create(:template, :device_template) }
  let(:device) { create(:device, chassis: chassis, metadata: {foo: :bar}) }
  let(:rack_owner) { create(:user) }

  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }

  describe "GET :structure" do
    let(:url_under_test) { urls.structure_api_v1_metrics_path }

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      let(:user) { authenticated_user }

      context "when upstream responds unsuccessfully" do
        before(:each) do
          result = GetUniqueMetricsJob::Result.new(false, metrics, "an error", 500)
          allow(GetUniqueMetricsJob).to receive(:perform_now).and_return(result)
        end

        let(:metrics) { [ ] }

        it "renders an upstream error response" do
          get url_under_test, headers: headers, as: :json
          expect(response).to have_http_status(502)
        end
      end

      context "when upstream responds successfully with multiple metrics" do
        before(:each) do
          result = GetUniqueMetricsJob::Result.new(true, metrics, nil, 200)
          allow(GetUniqueMetricsJob).to receive(:perform_now).and_return(result)
        end

        let(:metrics) {
          [
            {id: "caffeine.level", name: "caffeine.level", units: "", nature: "volatile", min: 32, max: 64},
            {id: "caffeine.consumption", name: "caffeine.consumption", units: "cups", nature: "volatile", min: 0, max: 4},
          ].map(&:with_indifferent_access)
        }
        let(:parsed_body) { JSON.parse(response.body) }
        let(:parsed_metrics) { parsed_body }

        include_examples "successful JSON response"

        it "includes correct number of metrics" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_metrics.length).to eq metrics.length
        end

        it "includes the expected metrics" do
          expected_ids = metrics.map { |m| m["id"] }.sort

          get url_under_test, headers: headers, as: :json

          retrieved_ids = parsed_metrics.map { |r| r["id"] }.sort
          expect(retrieved_ids).to eq expected_ids
        end

        it "has the correct attributes" do
          get url_under_test, headers: headers, as: :json

          parsed_metrics.sort { |a,b| a["id"] <=> b["id"] }
          expected_metrics = [
            {format: "%s", id: "caffeine.level", name: "caffeine.level", units: "", min: 32, max: 64},
            {format: "%s cups", id: "caffeine.consumption", name: "caffeine.consumption", units: "cups", min: 0, max: 4},
          ]
            .sort { |a,b| a[:id] <=> b[:id] }
            .map(&:stringify_keys)

          expect(parsed_metrics).to eq expected_metrics
        end
      end
    end
  end

  describe "GET :show" do
    let(:url_under_test) { urls.api_v1_device_metric_path(device, "power.level") }
    let(:headers) { {} }

    context "when not logged in" do
      include_examples "unauthorised JSON response" do
        let(:request_method) { :get }
      end
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      let(:user) { authenticated_user }

      context "when upstream responds unsuccessfully" do
        before(:each) do
          result = GetHistoricMetricValuesJob::Result.new(false, metric_values, "an error", 500)
          allow(GetHistoricMetricValuesJob).to receive(:perform_now).and_return(result)
        end

        let(:metric_values) { [ ] }

        it "renders an upstream error response" do
          get url_under_test, headers: headers, as: :json
          expect(response).to have_http_status(502)
        end
      end

      context "when upstream responds successfully with multiple metric values" do
        before(:each) do
          result = GetHistoricMetricValuesJob::Result.new(true, metric_values, nil, 200)
          allow(GetHistoricMetricValuesJob).to receive(:perform_now).and_return(result)
        end

        let(:metric_values) {
          [
            {timestamp: Time.current, value: 32},
            {timestamp: Time.current - 1.day, value: 64},
          ].map(&:with_indifferent_access)
        }
        let(:parsed_body) { JSON.parse(response.body) }
        let(:parsed_metric_values) { parsed_body }

        include_examples "successful JSON response" do
          let(:request_method) { :get }
        end

        it "includes correct number of metric_values" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_metric_values.length).to eq metric_values.length
        end

        it "includes the expected metric_values" do
          get url_under_test, headers: headers, as: :json
          expected = metric_values.map do |metric|
            metric["timestamp"] = metric["timestamp"].strftime("%Y-%m-%dT%H:%M:%S.%L%:z")
            metric
          end
          expect(parsed_metric_values).to eq(expected)
        end
      end
    end
  end
end
