require 'rails_helper'

RSpec.describe "Api::V1::Irv::RacksControllers", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }
  let(:index_url) { urls.api_v1_irv_racks_path }

  context "when not logged in" do
    describe "GET /" do
      it "returns an unauthorised response" do
        get index_url, headers: headers, as: :json
        expect(response).to have_http_status :unauthorized
      end

      it "returns an unauthorised response error message as JSON" do
        get index_url, headers: headers, as: :json
        expect(response.body).to eq ({error: "You need to sign in or sign up before continuing."}.to_json)
      end
    end
  end

  context "when logged in as admin" do
    include_context "Logged in as admin"

    shared_examples "successful JSON response" do
      it "renders a successful response" do
        get index_url, headers: headers, as: :json
        expect(response).to be_successful
      end

      it "returns a JSON document" do
        get index_url, headers: headers, as: :json
        expect{ JSON.parse(response.body) }.not_to raise_error
      end
    end

    context "when there are no racks" do
      describe "GET /" do
        let(:parsed_body) { JSON.parse(response.body) }
        let(:parsed_racks) { parsed_body["Racks"]["Rack"] }

        include_examples "successful JSON response"
        it "includes zero racks" do
          get index_url, headers: headers, as: :json
          expect(parsed_racks).to be_empty
        end
      end
    end

    context "when there is one rack" do
      let!(:template) { create(:template, :rack_template) }
      let!(:rack) { create(:rack, user: user, template: template) }

      describe "GET /" do
        let(:parsed_body) { JSON.parse(response.body) }
        let(:parsed_racks) { parsed_body["Racks"]["Rack"] }

        include_examples "successful JSON response"

        it "includes one rack" do
          get index_url, headers: headers, as: :json
          expect(parsed_racks).not_to be_a Array
          expect(parsed_racks).not_to be_nil
        end

        it "has the correct attributes" do
          get index_url, headers: headers, as: :json
          expect(parsed_racks["id"].to_i).to eq rack.id
          expect(parsed_racks["name"]).to eq rack.name
          expect(parsed_racks["uHeight"].to_i).to eq rack.u_height
          expected_template = {
            height: template.height.to_s,
            depth: template.depth.to_s,
            name: template.name,
          }.stringify_keys
          expect(parsed_racks["template"].slice(*expected_template.keys)).to eq expected_template
        end
      end
    end
  end
end
