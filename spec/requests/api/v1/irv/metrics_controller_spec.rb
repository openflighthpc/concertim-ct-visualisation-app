#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

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
