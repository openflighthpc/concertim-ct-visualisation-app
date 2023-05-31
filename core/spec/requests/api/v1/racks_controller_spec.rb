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
    end

    it "has the correct owner" do
      get url_under_test, headers: headers, as: :json
      expected_owner = {
        id: rack.user.id,
        login: rack.user.login,
        name: rack.user.name,
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
        let!(:rack) { create(:rack, user: user, template: template, metadata: rack_metadata) }
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
        let!(:racks) { create_list(:rack, 2, user: user, template: template, metadata: rack_metadata) }
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
    let!(:rack) { create(:rack, user: rack_owner, template: template, metadata: rack_metadata) }
    let(:rack_metadata) { {} }

    context "when not logged in" do
      let(:rack_owner) { create(:user) }
      include_examples "unauthorised JSON response"
    end

    context "when logged in as rack owner" do
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

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      let(:rack_owner) { create(:user) }
      let(:valid_attributes) {
        {
          rack: {
            u_height: 20,
            user_id: rack_owner.id,
            metadata: { "foo" => "bar" }
          }
        }
      }
      let(:invalid_attributes) {
        {
          rack: {
            u_height: -1,
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
          }.to change(Ivy::HwRack, :count).by(1)
        end

        it "renders a successful response" do
          send_request
          expect(response).to have_http_status :ok
        end

        it "includes the rack in the response" do
          send_request
          parsed_rack = JSON.parse(response.body)
          expect(parsed_rack["u_height"]).to eq valid_attributes[:rack][:u_height]
          expect(parsed_rack["owner"]["id"]).to eq valid_attributes[:rack][:user_id]
          expect(parsed_rack["metadata"]).to eq valid_attributes[:rack][:metadata]
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
          }.not_to change(Ivy::HwRack, :count)
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
      create(:rack, user: rack_owner, template: template, metadata: initial_rack_metadata, u_height: initial_u_height)
    }
    let(:initial_rack_metadata) { {} }
    let(:initial_u_height) { 20 }

    shared_examples "authorized user updating rack" do
      let(:valid_attributes) {
        {
          rack: {
            u_height: initial_u_height + 2,
            metadata: initial_rack_metadata.merge("foo" => "bar")
          }
        }
      }
      let(:invalid_attributes) {
        {
          rack: {
            u_height: -1,
            metadata: "should be an object"
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
      let(:rack_owner) { create(:user) }
    end

    context "when logged in as rack owner" do
      include_context "Logged in as non-admin"
      let(:rack_owner) { authenticated_user }
      include_examples "authorized user updating rack"
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
      include_examples "authorized user updating rack"
    end
  end
end