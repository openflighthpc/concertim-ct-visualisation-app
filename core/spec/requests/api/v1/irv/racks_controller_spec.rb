require 'rails_helper'

RSpec.describe "Api::V1::Irv::RacksControllers", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }

  describe "GET :index" do
    let(:url_under_test) { urls.api_v1_irv_racks_path }

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      let(:user) { authenticated_user }

      context "when there are no racks" do
        let(:parsed_body) { JSON.parse(response.body) }
        let(:parsed_racks) { parsed_body["Racks"]["Rack"] }

        include_examples "successful JSON response"

        it "includes zero racks" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_racks).to be_empty
        end
      end

      context "when there is one rack" do
        let!(:template) { create(:template, :rack_template) }
        let!(:rack) { create(:rack, user: user, template: template) }

        let(:parsed_body) { JSON.parse(response.body) }
        let(:parsed_racks) { parsed_body["Racks"]["Rack"] }

        include_examples "successful JSON response"

        it "includes one rack" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_racks).not_to be_a Array
          expect(parsed_racks).not_to be_nil
        end

        it "has the correct attributes" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_racks["id"].to_i).to eq rack.id
          expect(parsed_racks["name"]).to eq rack.name
          expect(parsed_racks["uHeight"].to_i).to eq rack.u_height
        end

        it "includes the rack's template" do
          get url_under_test, headers: headers, as: :json
          expected_template = {
            height: template.height.to_s,
            depth: template.depth.to_s,
            name: template.name,
          }.stringify_keys
          expect(parsed_racks["template"].slice(*expected_template.keys)).to eq expected_template
        end

        it "includes the rack's owner" do
          get url_under_test, headers: headers, as: :json
          expected_owner = {
            id: user.id.to_s,
            login: user.login,
            name: user.name,
          }.stringify_keys
          expect(parsed_racks["owner"].slice(*expected_owner.keys)).to eq expected_owner
        end
      end

      context "when there are two racks" do
        let!(:template) { create(:template, :rack_template) }
        let!(:racks) { create_list(:rack, 2, user: user, template: template) }

        let(:parsed_body) { JSON.parse(response.body) }
        let(:parsed_racks) { parsed_body["Racks"]["Rack"] }

        include_examples "successful JSON response"

        it "includes two racks" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_racks.length).to eq racks.length
        end

        it "includes the expected racks" do
          expected_ids = racks.map(&:id).sort

          get url_under_test, headers: headers, as: :json

          retrieved_ids = parsed_racks.map { |r| r["id"].to_i }.sort
          expect(retrieved_ids).to eq expected_ids
        end
      end
    end
  end
end
