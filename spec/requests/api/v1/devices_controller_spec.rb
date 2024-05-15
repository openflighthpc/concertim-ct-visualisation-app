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

RSpec.describe "Api::V1::DevicesControllers", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }
  let!(:rack_template) { create(:template, :rack_template) }
  let!(:rack) { create(:rack, template: rack_template) }
  let(:device_template) { create(:template, :device_template) }

  shared_examples "single device response examples" do
    it "has the correct attributes" do
      get url_under_test, headers: headers, as: :json
      expect(parsed_device["id"]).to eq device.id
      expect(parsed_device["name"]).to eq device.name
      expect(parsed_device["metadata"]).to eq device.metadata
      expect(parsed_device["cost"]).to eq "#{'%.2f' % device.cost}"
      if full_template_details
        expect(parsed_device["template"]["id"]).to eq device_template.id
      else
        expect(parsed_device["template_id"]).to eq device_template.id
      end
    end
  end

  describe "GET :index" do
    let(:url_under_test) { urls.api_v1_devices_path }
    let(:parsed_body) { JSON.parse(response.body) }
    let(:parsed_devices) { parsed_body }
    let(:full_template_details) { false }

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as super admin" do
      include_context "Logged in as admin"

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
        let!(:device) { create(:instance, chassis: chassis, metadata: {foo: :bar}) }
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
            create(:instance, metadata: {foo: "one"}, chassis: create(:chassis, template: dt, location: create(:location, rack: rack, start_u: 1))),
            create(:instance, metadata: {foo: "two"}, chassis: create(:chassis, template: dt, location: create(:location, rack: rack, start_u: 2))),
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
    let!(:device) { create(:instance, chassis: chassis) }
    let(:chassis) { create(:chassis, template: device_template, location: location) }
    let(:location) { create(:location, rack: rack) }
    let(:full_template_details) { true }

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as member of rack team" do
      include_context "Logged in as non-admin"
      include_examples "successful JSON response" do
        let!(:team_role) { create(:team_role, user: authenticated_user, team: rack.team) }
      end
    end

    context "when logged in as another user" do
      include_context "Logged in as non-admin"
      include_examples "forbidden JSON response" do
        let!(:team_role) { create(:team_role, user: authenticated_user) }
      end
    end

    context "when logged in as super admin" do
      include_context "Logged in as admin"
      include_examples "successful JSON response"

      let(:parsed_body) { JSON.parse(response.body) }
      let(:parsed_device) { parsed_body }

      include_examples "single device response examples"
    end
  end

  describe "PATCH :update" do
    let(:url_under_test) { urls.api_v1_device_path(device) }
    let!(:device) { create(:instance, chassis: chassis) }
    let(:chassis) { create(:chassis, template: device_template, location: location) }
    let(:location) { create(:location, rack: rack) }
    let(:full_template_details) { true }

    shared_examples "authorized user updating device" do
      let(:valid_attributes) {
        {
          device: {
            name: device.name + "-updated",
            metadata: device.metadata.merge("kate" => "kate"),
            status: "ACTIVE",
            cost: 99.99,
            details: {
              type: 'Device::ComputeDetails',
              public_ips: "1.1.1.1",
              private_ips: "2.2.2.2",
              ssh_key: "abc",
              login_user: "Billy Bob",
              volume_details: { id: "abc" }
            }
          }
        }
      }
      let(:invalid_attributes) {
        {
          device: {
            name: "so not valid",
            metadata: "should be an object",
            status: 'not a valid status',
            cost: -1,
            details: {
              type: 'a squirrel'
            }
          }
        }
      }
      let(:valid_partial_attributes) {
        {
          device: {
            name: device.name + "-updated",
            cost: 1138,
            details: {
              ssh_key: 'shibboleth'
            }
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
          expect(parsed_device["cost"]).to eq "#{'%.2f' % valid_attributes[:device][:cost]}"
          expect(parsed_device["template"]["id"]).to eq device_template.id

          parsed_details = parsed_device #['details']
          expect(parsed_details["public_ips"]).to eq valid_attributes[:device][:details][:public_ips]
          expect(parsed_details["private_ips"]).to eq valid_attributes[:device][:details][:private_ips]
          expect(parsed_details["ssh_key"]).to eq valid_attributes[:device][:details][:ssh_key]
          expect(parsed_details["login_user"]).to eq valid_attributes[:device][:details][:login_user]
          expect(parsed_details["volume_details"]["id"]).to eq valid_attributes[:device][:details][:volume_details][:id]
        end
      end

      context "with valid partial parameters" do
        def send_request
          patch url_under_test,
            params: valid_partial_attributes,
            headers: headers,
            as: :json
        end

        it "updates the specified parameters" do
          expect { send_request }.to change { device.reload.name }
            .and change { device.cost }
            .and change { device.details.ssh_key }
        end

        it "does not update parameters that were unspecified" do
          expect { send_request }.to not_change { device.status }
            .and not_change { device.metadata }
            .and not_change { device.template }
            .and not_change { device.details_type }
            .and not_change { device.details.public_ips }
            .and not_change { device.details.private_ips }
            .and not_change { device.details.login_user }
            .and not_change { device.details.volume_details }
        end
      end

      context "with legacy valid parameters" do
        let(:attributes) {
          {
            device: {
              name: device.name + "-updated",
              metadata: device.metadata.merge("kate" => "kate"),
              status: "ACTIVE",
              cost: 99.99,
              public_ips: "1.1.1.1",
              private_ips: "2.2.2.2",
              ssh_key: "abc",
              login_user: "Billy Bob",
              volume_details: { id: "abc" }
            }
          }
        }

        def send_request
          patch url_under_test,
            params: attributes,
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
          expect(device.metadata).not_to eq attributes[:device][:metadata]

          send_request

          parsed_device = JSON.parse(response.body)
          expect(parsed_device["name"]).to eq attributes[:device][:name]
          expect(parsed_device["metadata"]).to eq attributes[:device][:metadata]
          expect(parsed_device["status"]).to eq attributes[:device][:status]
          expect(parsed_device["cost"]).to eq "#{'%.2f' % attributes[:device][:cost]}"
          expect(parsed_device["template"]["id"]).to eq device_template.id
          expect(parsed_device["public_ips"]).to eq attributes[:device][:public_ips]
          expect(parsed_device["private_ips"]).to eq attributes[:device][:private_ips]
          expect(parsed_device["ssh_key"]).to eq attributes[:device][:ssh_key]
          expect(parsed_device["login_user"]).to eq attributes[:device][:login_user]
          expect(parsed_device["volume_details"]["id"]).to eq attributes[:device][:volume_details][:id]
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

      context "when trying to change the type of a device's details" do
        let(:params) {
          {
            device: {
              details: {
                type: 'Location'
              }
            }
          }
        }
        def send_request
          patch url_under_test,
            params: params,
            headers: headers,
            as: :json
        end
        it "renders an unprocessable entity response" do
          send_request
          expect(response).to have_http_status :unprocessable_entity
        end
      end

      context 'with a network device' do
        let(:device_template) { create(:template, :network_device_template) }
        let(:details) { create(:device_network_details) }
        let!(:device) { create(:network, chassis: chassis, details: details) }

        context "with valid parameters" do
          let(:attributes) {
            {
              device: {
                name: device.name + "-updated",
                status: "ACTIVE",
                cost: 42.42,
                details: {
                  mtu: 1138
                }
              }
            }
          }
          def send_request
            patch url_under_test,
              params: attributes,
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
            send_request

            parsed_device = JSON.parse(response.body)
            expect(parsed_device["name"]).to eq attributes[:device][:name]
            expect(parsed_device["status"]).to eq attributes[:device][:status]
            expect(parsed_device["cost"]).to eq "#{'%.2f' % attributes[:device][:cost]}"
            parsed_details = parsed_device # ['details'] after revertion of 6b8d3e9
            expect(parsed_details["mtu"]).to eq attributes[:device][:details][:mtu]
          end
        end
      end

      context 'with a volume device' do
        let(:device_template) { create(:template, :volume_device_template) }
        let(:details) { create(:device_volume_details) }
        let!(:device) { create(:volume, chassis: chassis, details: details) }

        context "with valid parameters" do
          let(:attributes) {
            {
              device: {
                name: device.name + "-updated",
                status: "ACTIVE",
                details: {
                  bootable: true
                }
              }
            }
          }
          def send_request
            patch url_under_test,
              params: attributes,
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
            send_request

            parsed_device = JSON.parse(response.body)
            expect(parsed_device["name"]).to eq attributes[:device][:name]
            expect(parsed_device["status"]).to eq attributes[:device][:status]
            parsed_details = parsed_device # ['details'] after revertion of 6b8d3e9
            expect(parsed_details["bootable"]).to eq attributes[:device][:details][:bootable]
          end
        end
      end
    end

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as device's rack team member" do
      include_context "Logged in as non-admin"
      include_examples "forbidden JSON response" do
        let(:request_method) { :patch }
        let!(:team_role) { create(:team_role, team: device.rack.team, user: authenticated_user, role: "member") }
      end
    end

    context "when logged in as device's rack team admin" do
      include_context "Logged in as non-admin"
      let!(:team_role) { create(:team_role, team: device.rack.team, user: authenticated_user, role: "admin") }
      include_examples "authorized user updating device"
    end

    context "when logged in as another user" do
      include_context "Logged in as non-admin"
      include_examples "forbidden JSON response" do
        let(:request_method) { :patch }
        let!(:team_role) { create(:team_role, user: authenticated_user) }
      end
    end

    context "when logged in as super admin" do
      include_context "Logged in as admin"
      include_examples "authorized user updating device"
    end
  end
end
