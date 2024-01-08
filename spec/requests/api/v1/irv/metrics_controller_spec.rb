require 'rails_helper'

RSpec.describe "Api::V1::Irv::MetricsController", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }
  let(:metric_name) { "power.level" }

  describe "POST :show" do
    let(:url_under_test) { urls.api_v1_irv_metric_path(metric_name) }

    context "when not logged in" do
      include_examples "unauthorised JSON response" do
        let(:request_method) { :post }
      end
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      let(:user) { authenticated_user }

      context "when upstream responds unsuccessfully" do
        before(:each) do
          result = GetValuesForDevicesWithMetricJob::Result.new(false, metric_values, "an error", 500)
          allow(GetValuesForDevicesWithMetricJob).to receive(:perform_now).and_return(result)
        end

        let(:metric_values) { [ ] }

        it "renders an upstream error response" do
          post url_under_test, headers: headers, as: :json
          expect(response).to have_http_status(502)
        end
      end

      context "when upstream responds successfully with multiple metric values" do
        before(:each) do
          result = GetValuesForDevicesWithMetricJob::Result.new(true, metric_values, nil, 200)
          allow(GetValuesForDevicesWithMetricJob).to receive(:perform_now).and_return(result)
        end

        let(:metric_values) {
          [
            {id: "1", value: 32},
            {id: "2", value: 64},
          ].map(&:with_indifferent_access)
        }
        let(:parsed_body) { JSON.parse(response.body) }
        let(:parsed_metric_values) { parsed_body }

        include_examples "successful JSON response" do
          let(:request_method) { :post }
        end

        it "includes correct number of metric_values" do
          post url_under_test, headers: headers, as: :json
          expect(parsed_metric_values.length).to eq metric_values.length
        end

        it "includes the expected metric_values" do
          post url_under_test, headers: headers, as: :json
          expected_metric_values = [{"id" => "1", "value" => 32}, {"id" => "2", "value" => 64}]
          expected_response = {
            "name" => metric_name, "values" => {"devices" => expected_metric_values, "chassis" => []}
          }
          expect(parsed_metric_values).to eq(expected_response)
        end

        it "supports filtering values by device id" do
          post url_under_test, headers: headers, as: :json, params: {device_ids: ["2"], tagged_devices_ids: []}
          expected_metric_values = [{"id" => "2", "value" => 64}]
          expected_response = {
            "name" => metric_name, "values" => {"devices" => expected_metric_values, "chassis" => []}
          }
          expect(parsed_metric_values).to eq(expected_response)
        end

      end
    end
  end
end
