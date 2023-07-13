require 'rails_helper'

RSpec.describe "Api::V1::DevicesControllers", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }
  let!(:rack_template) { create(:template, :rack_template) }
  let!(:rack) { create(:rack, user: rack_owner, template: rack_template) }
  let(:device_template) { create(:template, :device_template) }

  shared_examples "single device response examples" do
    it "has the correct attributes" do
      get url_under_test, headers: headers, as: :json
      expect(parsed_device["id"]).to eq device.id
      expect(parsed_device["name"]).to eq device.name
      expect(parsed_device["metadata"]).to eq device.metadata
    end
  end

  describe "GET :index" do
    let(:url_under_test) { urls.api_v1_devices_path }
    let(:parsed_body) { JSON.parse(response.body) }
    let(:parsed_devices) { parsed_body }

    context "when not logged in" do
      let(:rack_owner) { create(:user) }
      include_examples "unauthorised JSON response"
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      let(:rack_owner) { create(:user) }

      context "when there are no racks" do
        let(:parsed_body) { JSON.parse(response.body) }
        let(:parsed_devices) { parsed_body }

        include_examples "successful JSON response"

        it "includes zero devices" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_devices).to be_empty
        end
      end

      context "when there is one device" do
        let!(:device) { create(:device, chassis: chassis, metadata: {foo: :bar}) }
        let(:chassis) { create(:chassis, template: device_template, location: location) }
        let(:location) { create(:location, rack: rack) }

        let(:parsed_device) { parsed_devices.first }

        include_examples "successful JSON response"

        it "includes one device" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_devices.length).to eq 1
        end

        include_examples "single device response examples"
      end

      context "when there are two devices" do
        let!(:devices) {
          dt = device_template
          [
            create(:device, metadata: {foo: "one"}, chassis: create(:chassis, template: dt, location: create(:location, rack: rack, start_u: 1))),
            create(:device, metadata: {foo: "two"}, chassis: create(:chassis, template: dt, location: create(:location, rack: rack, start_u: 2))),
          ]
        }

        include_examples "successful JSON response"

        it "includes two devices" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_devices.length).to eq devices.length
        end

        it "includes the expected devices" do
          expected_ids = devices.map(&:id).sort

          get url_under_test, headers: headers, as: :json

          retrieved_ids = parsed_devices.map { |d| d["id"] }.sort
          expect(retrieved_ids).to eq expected_ids
        end
      end
    end
  end

  describe "GET :show" do
    let(:url_under_test) { urls.api_v1_device_path(device) }
    let!(:device) { create(:device, chassis: chassis) }
    let(:chassis) { create(:chassis, template: device_template, location: location) }
    let(:location) { create(:location, rack: rack) }


    context "when not logged in" do
      let(:rack_owner) { create(:user) }
      include_examples "unauthorised JSON response"
    end

    context "when logged in as device owner" do
      include_context "Logged in as non-admin"
      include_examples "successful JSON response" do
        let(:rack_owner) { authenticated_user }
      end
    end

    context "when logged in as another user" do
      include_context "Logged in as non-admin"
      include_examples "forbidden JSON response" do
        let(:rack_owner) { create(:user) }
      end
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      let(:rack_owner) { create(:user) }
      include_examples "successful JSON response"

      let(:parsed_body) { JSON.parse(response.body) }
      let(:parsed_device) { parsed_body }

      include_examples "single device response examples"
    end
  end

  describe "PATCH :update" do
    let(:url_under_test) { urls.api_v1_device_path(device) }
    let!(:device) { create(:device, chassis: chassis) }
    let(:chassis) { create(:chassis, template: device_template, location: location) }
    let(:location) { create(:location, rack: rack) }

    shared_examples "authorized user updating device" do
      let(:valid_attributes) {
        {
          device: {
            name: device.name + "-updated",
            metadata: device.metadata.merge("kate" => "kate"),
            status: "ACTIVE",
          }
        }
      }
      let(:invalid_attributes) {
        {
          device: {
            name: "so not valid",
            metadata: "should be an object",
            status: 'not a valid status',
          }
        }
      }

      context "with valid parameters" do
        def send_request
          patch url_under_test,
            params: valid_attributes,
            headers: headers,
            as: :json
        end

        it "renders a successful response" do
          send_request
          expect(response).to have_http_status :ok
        end

        it "updates the device" do
          expect {
            send_request
          }.to change{ device.reload.updated_at }
        end

        it "includes the device in the response" do
          expect(device.metadata).not_to eq valid_attributes[:device][:metadata]

          send_request

          parsed_device = JSON.parse(response.body)
          expect(parsed_device["name"]).to eq valid_attributes[:device][:name]
          expect(parsed_device["metadata"]).to eq valid_attributes[:device][:metadata]
          expect(parsed_device["status"]).to eq valid_attributes[:device][:status]
        end
      end

      context "with invalid parameters" do
        def send_request
          patch url_under_test,
            params: invalid_attributes,
            headers: headers,
            as: :json
        end

        it "does not update the device" do
          expect {
            send_request
          }.not_to change{ device.reload.updated_at }
        end

        it "renders an unprocessable entity response" do
          send_request
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "when not logged in" do
      include_examples "unauthorised JSON response"
      let(:rack_owner) { create(:user) }
    end

    context "when logged in as device owner" do
      include_context "Logged in as non-admin"
      let(:rack_owner) { authenticated_user }
      include_examples "authorized user updating device"
    end

    context "when logged in as another user" do
      include_context "Logged in as non-admin"
      include_examples "forbidden JSON response" do
        let(:rack_owner) { create(:user) }
      end
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      let(:rack_owner) { create(:user) }
      include_examples "authorized user updating device"
    end
  end
end
