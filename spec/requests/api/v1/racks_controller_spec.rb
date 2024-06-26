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

RSpec.describe "Api::V1::RacksControllers", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }
  let!(:template) { create(:template, :rack_template) }

  shared_examples "single rack response examples" do
    it "has the correct attributes" do
      get url_under_test, headers: headers, as: :json
      expect(parsed_rack["id"]).to eq rack.id
      expect(parsed_rack["name"]).to eq rack.name
      expect(parsed_rack["u_height"]).to eq rack.u_height
      expect(parsed_rack["cost"]).to eq "#{'%.2f' % rack.cost}"
      expect(parsed_rack["creation_output"]).to eq rack.creation_output
      expect(parsed_rack["network_details"]["id"]).to eq rack.network_details["id"]
      expect(parsed_rack["order_id"]).to eq rack.order_id
    end

    it "has the correct owner" do
      get url_under_test, headers: headers, as: :json
      expected_owner = {
        id: rack.team.id,
        name: rack.team.name,
      }.stringify_keys
      expect(parsed_rack["owner"].slice(*expected_owner.keys)).to eq expected_owner
    end

    context "when the rack has no metadata" do
      let(:rack_metadata) { {} }

      it "has the correct metadata" do
        expect(rack.metadata).to be_kind_of Object
        expect(rack.metadata).to be_empty

        get url_under_test, headers: headers, as: :json

        expect(parsed_rack["metadata"]).to eq({})
      end
    end

    context "when the rack has some metadata" do
      let(:rack_metadata) { {"foo" => "bar", "nested" => {"bob" => "kate"}} }

      it "has the correct metadata" do
        expect(rack.metadata).to be_kind_of Object
        expect(rack.metadata).not_to be_empty

        get url_under_test, headers: headers, as: :json

        expect(parsed_rack["metadata"]).to eq rack_metadata
      end
    end
  end

  describe "GET :index" do
    let(:url_under_test) { urls.api_v1_racks_path }

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      let(:user) { authenticated_user }

      context "when there are no racks" do
        let(:parsed_body) { JSON.parse(response.body) }
        let(:parsed_racks) { parsed_body }

        include_examples "successful JSON response"

        it "includes zero racks" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_racks).to be_empty
        end
      end

      context "when there is one rack" do
        let!(:rack) { create(:rack, template: template, metadata: rack_metadata) }
        let(:rack_metadata) { {} }

        let(:parsed_body) { JSON.parse(response.body) }
        let(:parsed_racks) { parsed_body }
        let(:parsed_rack) { parsed_racks.first }

        include_examples "successful JSON response"

        it "includes one rack" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_racks.length).to eq 1
        end

        it "does not include device listing" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_rack).not_to have_key "devices"
        end

        include_examples "single rack response examples"
      end

      context "when there are two racks" do
        let!(:racks) { create_list(:rack, 2, template: template, metadata: rack_metadata) }
        let(:rack_metadata) { {} }

        let(:parsed_body) { JSON.parse(response.body) }
        let(:parsed_racks) { parsed_body }

        include_examples "successful JSON response"

        it "includes two racks" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_racks.length).to eq racks.length
        end

        it "includes the expected racks" do
          expected_ids = racks.map(&:id).sort

          get url_under_test, headers: headers, as: :json

          retrieved_ids = parsed_racks.map { |r| r["id"] }.sort
          expect(retrieved_ids).to eq expected_ids
        end
      end
    end
  end

  describe "GET :show" do
    let(:url_under_test) { urls.api_v1_rack_path(rack) }
    let!(:rack) { create(:rack, template: template, metadata: rack_metadata) }
    let(:rack_metadata) { {} }

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as rack team member" do
      include_context "Logged in as non-admin"
      include_examples "successful JSON response" do
        let!(:role) { create(:team_role, team: rack.team, user: authenticated_user) }
      end
    end

    context "when logged in as non team member" do
      include_context "Logged in as non-admin"
      include_examples "forbidden JSON response" do
        let!(:role) { create(:team_role, user: authenticated_user) }
      end
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      include_examples "successful JSON response"

      let(:parsed_body) { JSON.parse(response.body) }
      let(:parsed_rack) { parsed_body }

      it "includes device listing" do
        rack_devices = rack.devices.occupying_rack_u
        expected_ids = rack_devices.map(&:id).sort

        get url_under_test, headers: headers, as: :json

        expect(parsed_rack).to have_key "devices"
        expect(parsed_rack["devices"].length).to eq rack_devices.length
        got_ids = parsed_rack["devices"].map { |d| d["id"] }.sort
        expect(got_ids).to eq expected_ids
      end

      include_examples "single rack response examples"
    end
  end

  describe "POST :create" do
    let(:url_under_test) { urls.api_v1_racks_path }
    let!(:team) { create(:team) }

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      let(:valid_attributes) {
        {
          rack: {
            u_height: 20,
            team_id: team.id,
            status: 'IN_PROGRESS',
            metadata: { "foo" => "bar" },
            creation_output: "all tasks complete",
            network_details: { id: "abc" },
            order_id: Faker::Alphanumeric.alphanumeric(number: 10),
          }
        }
      }
      let(:invalid_attributes) {
        {
          rack: {
            u_height: -1,
            status: 'not a valid status',
            metadata: "should be an object"
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

        it "creates a new rack" do
          expect {
            send_request
          }.to change(HwRack, :count).by(1)
        end

        it "renders a successful response" do
          send_request
          expect(response).to have_http_status :ok
        end

        it "includes the rack in the response" do
          send_request
          parsed_rack = JSON.parse(response.body)
          expect(parsed_rack["u_height"]).to eq valid_attributes[:rack][:u_height]
          expect(parsed_rack["owner"]["id"]).to eq valid_attributes[:rack][:team_id]
          expect(parsed_rack["metadata"]).to eq valid_attributes[:rack][:metadata]
          expect(parsed_rack["cost"]).to eq "0.00"
          expect(parsed_rack["creation_output"]).to eq valid_attributes[:rack][:creation_output]
          expect(parsed_rack["network_details"]["id"]).to eq valid_attributes[:rack][:network_details][:id]
          expect(parsed_rack["order_id"]).to eq valid_attributes[:rack][:order_id]
        end
      end

      context "with invalid parameters" do
        def send_request
          post url_under_test,
            params: invalid_attributes,
            headers: headers,
            as: :json
        end

        it "does not create a new rack" do
          expect {
            send_request
          }.not_to change(HwRack, :count)
        end

        it "renders an unprocessable entity response" do
          send_request
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end
  end

  describe "PATCH :update" do
    let(:url_under_test) { urls.api_v1_rack_path(rack) }
    let!(:rack) {
      create(:rack,
        template: template,
        metadata: initial_rack_metadata,
        u_height: initial_u_height,
        status: 'IN_PROGRESS',
        order_id: initial_order_id,
      )
    }
    let(:initial_rack_metadata) { {} }
    let(:initial_u_height) { 20 }
    let(:initial_order_id) { Faker::Alphanumeric.alphanumeric(number: 10) }

    shared_examples "authorized user updating rack" do
      let(:valid_attributes) {
        {
          rack: {
            u_height: initial_u_height + 2,
            status: 'ACTIVE',
            metadata: initial_rack_metadata.merge("foo" => "bar"),
            cost: 99.99,
            creation_output: "all tasks complete",
            network_details: { id: "abc" },
            order_id: Faker::Alphanumeric.alphanumeric(number: 10),
          }
        }
      }
      let(:invalid_attributes) {
        {
          rack: {
            u_height: -1,
            metadata: "should be an object",
            cost: -1
          }
        }
      }

      context "with valid parameters" do
        before(:each) do
          # We'll get unexpected errors if this isn't true.
          expect(initial_order_id).not_to eq valid_attributes[:rack][:order_id]
        end

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

        it "updates the rack" do
          expect {
            send_request
          }.to change{ rack.reload.updated_at }
        end

        it "includes the rack in the response" do
          send_request
          parsed_rack = JSON.parse(response.body)
          expect(parsed_rack["u_height"]).to eq valid_attributes[:rack][:u_height]
          expect(parsed_rack["metadata"]).to eq valid_attributes[:rack][:metadata]
          expect(parsed_rack["status"]).to eq valid_attributes[:rack][:status]
          expect(parsed_rack["cost"]).to eq  "#{'%.2f' % valid_attributes[:rack][:cost]}"
          expect(parsed_rack["creation_output"]).to eq valid_attributes[:rack][:creation_output]
          expect(parsed_rack["network_details"]["id"]).to eq valid_attributes[:rack][:network_details][:id]
          if can_update_order_id
            expect(parsed_rack["order_id"]).to eq valid_attributes[:rack][:order_id]
          else
            expect(parsed_rack["order_id"]).to eq initial_order_id
          end
        end
      end

      context "with invalid parameters" do
        def send_request
          patch url_under_test,
            params: invalid_attributes,
            headers: headers,
            as: :json
        end

        it "does not update the rack" do
          expect {
            send_request
          }.not_to change{ rack.reload.updated_at }
        end

        it "renders an unprocessable entity response" do
          send_request
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as admin of rack's team" do
      include_context "Logged in as non-admin"
      let!(:team_role) { create(:team_role, user: authenticated_user, team: rack.team, role: "admin") }
      include_examples "authorized user updating rack" do
        let(:can_update_order_id) { false }
      end
    end

    context "when logged in as member of rack's team" do
      include_context "Logged in as non-admin"
      let!(:team_role) { create(:team_role, user: authenticated_user, team: rack.team, role: "member") }
      include_examples "forbidden JSON response" do
        let(:request_method) { :patch }
        let!(:team_role) { create(:team_role, user: authenticated_user) }
      end
    end

    context "when logged in as another user" do
      include_context "Logged in as non-admin"
      include_examples "forbidden JSON response" do
        let(:request_method) { :patch }
        let!(:team_role) { create(:team_role, user: authenticated_user) }
      end
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      include_examples "authorized user updating rack" do
        let(:can_update_order_id) { true }
      end
    end
  end
end
