require 'rails_helper'

RSpec.describe "Api::V1::NodesControllers", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }
  let!(:rack_template) { create(:template, :rack_template) }
  let!(:rack) { create(:rack, user: rack_owner, template: rack_template) }
  let(:device_template) { create(:template, :device_template) }
  let(:rack_owner) { create(:user) }

  describe "POST :create" do
    let(:url_under_test) { urls.api_v1_nodes_path }

    context "when not logged in" do
      include_examples "unauthorised JSON response" do
        let(:request_method) { :post }
      end
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      let(:valid_attributes) {
        {
          template_id: device_template.id,
          device: {
            name: "device-1",
            description: "device-1 description",
            location: {
              rack_id: rack.id,
              start_u: 1,
              facing: 'f',
            },
            cost: 77.77,
            details: {
              type: 'Device::ComputeDetails',
              public_ips: "1.1.1.1, 2.2.2.2",
              private_ips: "3.3.3.3, 4.4.4.4",
              ssh_key: "abc",
              login_user: "Billy Bob",
              volume_details: {id: "abc"},
            },
            metadata: { "foo" => "bar", "baz" => "qux" },
            status: 'IN_PROGRESS',
          }
        }
      }
      let(:invalid_attributes) {
        {
          template_id: device_template.id,
          device: {
            name: "not a valid name",
            status: 'not a valid status',
            details: {
              type: 'herring'
            }
          }
        }
      }

      context "with valid parameters" do
        def send_request
          post url_under_test,
            params: valid_attributes,
            headers: headers,
            as: :json
        end

        it "creates a new device" do
          expect {
            send_request
          }.to change(Device, :count).by(1)
        end

        it "renders a successful response" do
          send_request
          expect(response).to have_http_status :ok
        end

        it "includes the device in the response" do
          send_request
          parsed_device = JSON.parse(response.body)

          expected_location = valid_attributes[:device][:location].merge(
            rack_id: rack.id,
            end_u: valid_attributes[:device][:location][:start_u] + device_template.height - 1,
            type: "rack",
            depth: device_template.depth,
          ).stringify_keys

          expect(parsed_device["name"]).to eq valid_attributes[:device][:name]
          expect(parsed_device["description"]).to eq valid_attributes[:device][:description]
          expect(parsed_device["location"]).to eq expected_location
          expect(parsed_device["metadata"]).to eq valid_attributes[:device][:metadata]
          expect(parsed_device["status"]).to eq valid_attributes[:device][:status]
          expect(parsed_device["template"]["id"]).to eq valid_attributes[:template_id]
          expect(parsed_device["cost"]).to eq "#{'%.2f' % valid_attributes[:device][:cost]}"

          parsed_details = parsed_device["details"]
          expect(parsed_details["public_ips"]).to eq valid_attributes[:device][:details][:public_ips]
          expect(parsed_details["private_ips"]).to eq valid_attributes[:device][:details][:private_ips]
          expect(parsed_details["ssh_key"]).to eq valid_attributes[:device][:details][:ssh_key]
          expect(parsed_details["login_user"]).to eq valid_attributes[:device][:details][:login_user]
          expect(parsed_details["volume_details"]["id"]).to eq valid_attributes[:device][:details][:volume_details][:id]
        end
      end

      context "with invalid parameters" do
        def send_request
          post url_under_test,
            params: invalid_attributes,
            headers: headers,
            as: :json
        end

        it "does not create a new device" do
          expect {
            send_request
          }.not_to change(Device, :count)
        end

        it "renders an unprocessable entity response" do
          send_request
          expect(response).to have_http_status :unprocessable_entity
        end
      end

      context "with parameters for a network device" do
        let(:device_template) { create(:template, :network_device_template) }
        let(:valid_attributes) {
          {
            template_id: device_template.id,
            device: {
              name: "net-1",
              description: "net-1 description",
              location: {
                rack_id: rack.id,
                start_u: 1,
                facing: 'f',
              },
              cost: 77.77,
              details: {
                type: 'Device::NetworkDetails',
                mtu: 1138,
                dns_domain: 'moose.net'
              },
              metadata: { "foo" => "bar", "baz" => "qux" },
              status: 'IN_PROGRESS',
            }
          }
        }

        def send_request
          post url_under_test,
            params: valid_attributes,
            headers: headers,
            as: :json
        end

        it "creates a new device" do
          expect {
            send_request
          }.to change(Device, :count).by(1)
        end

        it "renders a successful response" do
          send_request
          expect(response).to have_http_status :ok
        end

        it "includes the device in the response" do
          send_request
          parsed_device = JSON.parse(response.body)

          expected_location = valid_attributes[:device][:location].merge(
            rack_id: rack.id,
            end_u: valid_attributes[:device][:location][:start_u] + device_template.height - 1,
            type: "rack",
            depth: device_template.depth,
          ).stringify_keys

          expect(parsed_device["name"]).to eq valid_attributes[:device][:name]
          expect(parsed_device["description"]).to eq valid_attributes[:device][:description]
          expect(parsed_device["location"]).to eq expected_location
          expect(parsed_device["metadata"]).to eq valid_attributes[:device][:metadata]
          expect(parsed_device["status"]).to eq valid_attributes[:device][:status]
          expect(parsed_device["template"]["id"]).to eq valid_attributes[:template_id]
          expect(parsed_device["cost"]).to eq "#{'%.2f' % valid_attributes[:device][:cost]}"

          parsed_details = parsed_device #["details"]
          expect(parsed_details["mtu"]).to eq valid_attributes[:device][:details][:mtu]
          expect(parsed_details["dns_domain"]).to eq valid_attributes[:device][:details][:dns_domain]
        end
      end

      context "with parameters for a volume device" do
        let(:device_template) { create(:template, :volume_device_template) }
        let(:valid_attributes) {
          {
            template_id: device_template.id,
            device: {
              name: "vol-1",
              description: "vol-1 description",
              location: {
                rack_id: rack.id,
                start_u: 1,
                facing: 'f',
              },
              cost: 77.77,
              details: {
                type: 'Device::VolumeDetails',
                bootable: true,
                size: 4
              },
              metadata: { "foo" => "bar", "baz" => "qux" },
              status: 'IN_PROGRESS',
            }
          }
        }

        def send_request
          post url_under_test,
            params: valid_attributes,
            headers: headers,
            as: :json
        end

        it "creates a new device" do
          expect {
            send_request
          }.to change(Device, :count).by(1)
        end

        it "renders a successful response" do
          send_request
          expect(response).to have_http_status :ok
        end

        it "includes the device in the response" do
          send_request
          parsed_device = JSON.parse(response.body)

          expect(parsed_device["name"]).to eq valid_attributes[:device][:name]
          expect(parsed_device["description"]).to eq valid_attributes[:device][:description]
          expect(parsed_device["metadata"]).to eq valid_attributes[:device][:metadata]
          expect(parsed_device["status"]).to eq valid_attributes[:device][:status]
          expect(parsed_device["template"]["id"]).to eq valid_attributes[:template_id]
          expect(parsed_device["cost"]).to eq "#{'%.2f' % valid_attributes[:device][:cost]}"

          parsed_details = parsed_device #["details"]
          expect(parsed_details["bootable"]).to eq valid_attributes[:device][:details][:bootable]
          expect(parsed_details["size"]).to eq valid_attributes[:device][:details][:size]
        end
      end
    end
  end
end
