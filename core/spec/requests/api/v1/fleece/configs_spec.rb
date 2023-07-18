require 'rails_helper'

RSpec.describe "Api::V1::Fleece::Configs", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }

  describe "GET :show" do
    let(:url_under_test) { urls.api_v1_fleece_config_path }

    let(:parsed_body) { JSON.parse(response.body) }
    let(:parsed_config) { parsed_body }

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as non-admin" do
      include_context "Logged in as non-admin"
      include_examples "forbidden JSON response"
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"

      context "when there is not yet a fleece config" do
        before(:each) { expect(Fleece::Config.count).to eq 0 }

        it "responds with a 404 response" do
          get url_under_test, headers: headers, as: :json
          expect(response).to have_http_status :not_found
        end
      end

      context "when there is already a fleece config" do
        let!(:fleece_config) { create(:fleece_config) }

        include_examples "successful JSON response"

        it "contains the config in the response body" do
          get url_under_test, headers: headers, as: :json

          expect(parsed_config["host_url"]).to eq fleece_config.host_url
          expect(parsed_config["internal_auth_url"]).to eq fleece_config.internal_auth_url
          expect(parsed_config["admin_user_id"]).to eq fleece_config.admin_user_id
          expect(parsed_config["admin_password"]).to eq fleece_config.admin_password
          expect(parsed_config["admin_project_id"]).to eq fleece_config.admin_project_id
          expect(parsed_config["user_handler_port"]).to eq fleece_config.user_handler_port
          expect(parsed_config["cluster_builder_port"]).to eq fleece_config.cluster_builder_port
        end
      end
    end
  end
end
