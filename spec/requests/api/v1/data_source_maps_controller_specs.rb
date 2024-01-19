require 'rails_helper'

RSpec.describe "Api::V1::DataSourceMapsController", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }
  let!(:rack_template) { create(:template, :rack_template) }
  let!(:rack) { create(:rack, template: rack_template) }
  let(:device_template) { create(:template, :device_template) }

  describe "GET :index" do
    let(:url_under_test) { urls.api_v1_data_source_maps_path }

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"

      context "when there are no devices" do
        let(:expected_response) { {} }
        let(:parsed_body) { JSON.parse(response.body) }

        include_examples "successful JSON response"

        it "includes an empty JSON object response" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_body).to eq(expected_response)
        end
      end

      context "when there are multiple devices" do
        let!(:devices) {
          dt = device_template
          [
            create(:device, metadata: {foo: "one"}, chassis: create(:chassis, template: dt, location: create(:location, rack: rack, start_u: 1))),
            create(:device, metadata: {foo: "two"}, chassis: create(:chassis, template: dt, location: create(:location, rack: rack, start_u: 2))),
          ]
        }
        let(:expected_response) {
          r = {"unspecified" => {"unspecified" => {}}}
          devices.each do |d|
            r["unspecified"]["unspecified"]["device:#{d.id}"] = d.id.to_s
          end
          r
        }
        let(:parsed_body) { JSON.parse(response.body) }

        include_examples "successful JSON response"

        it "includes the expected response" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_body).to eq(expected_response)
        end
      end
    end
  end
end
