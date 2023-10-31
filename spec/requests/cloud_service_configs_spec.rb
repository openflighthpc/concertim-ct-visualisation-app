require 'rails_helper'

RSpec.describe "Configs", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }

  describe "GET :show" do
    let(:url_under_test) { urls.cloud_service_config_path }
    before(:each) { create(:cloud_service_config) }

    context "when not logged in" do
      include_examples "unauthorised HTML request"
    end

    context "when logged in as non-admin" do
      include_context "Logged in as non-admin"
      include_examples "forbidden HTML request"
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      include_examples "successful HTML response"
    end
  end

  describe "GET :new" do
    let(:url_under_test) { urls.new_cloud_service_config_path }

    context "when logged in as admin" do
      include_context "Logged in as admin"

      context "when there is not yet a config" do
        include_examples "successful HTML response"
      end

      context "when there is already a config" do
        before(:each) { create(:cloud_service_config) }

        it "redirects to the edit page" do
          get url_under_test, headers: headers
          expect(response).to redirect_to urls.edit_cloud_service_config_path
        end
      end
    end
  end

  describe "GET :edit" do
    let(:url_under_test) { urls.edit_cloud_service_config_path }

    context "when logged in as admin" do
      include_context "Logged in as admin"

      context "when there is not yet a config" do
        before(:each) { expect(CloudServiceConfig.count).to eq 0 }

        it "redirects to the new page" do
          get url_under_test, headers: headers
          expect(response).to redirect_to urls.new_cloud_service_config_path
        end
      end

      context "when there is already a config" do
        before(:each) { create(:cloud_service_config) }

        include_examples "successful HTML response"
      end
    end
  end

  describe "POST :create" do
    context "when logged in as admin" do
      include_context "Logged in as admin"

      let(:url_under_test) { urls.cloud_service_config_path }
      let(:model_under_test) { CloudServiceConfig }
      let(:expected_redirect_url) { urls.cloud_service_config_path }

      let(:valid_attributes) do
        {cloud_service_config: attributes_for(:cloud_service_config)}
      end
      let(:invalid_attributes) do
        {cloud_service_config: {cluster_builder_base_url: -1}}
      end

      let(:param_key) { model_under_test.model_name.param_key }

      context "with valid parameters" do
        def send_request
          post url_under_test,
            params: valid_attributes,
            headers: headers
        end

        it "creates a new record" do
          expect {
            send_request
          }.to change(model_under_test, :count).by(1)
        end

        it "redirects to the expected url" do
          send_request
          expect(response).to redirect_to(expected_redirect_url)
        end

        it "sets the expected attributes" do
          send_request
          object_under_test = model_under_test.all.order(:created_at).last

          valid_attributes.stringify_keys[param_key].each do |key, value|
            expect(object_under_test.send(key)).to eq value
          end
        end
      end

      context "with invalid parameters" do
        def send_request
          post url_under_test,
            params: invalid_attributes,
            headers: headers
        end

        it "does not create a new record" do
          expect {
            send_request
          }.not_to change(model_under_test, :count)
        end

        it "renders an unprocessable entity response" do
          send_request
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end
  end

  describe "PATCH :update" do
    context "when logged in as admin" do
      include_context "Logged in as admin"

      let!(:config) { create(:cloud_service_config) }

      let(:url_under_test) { urls.cloud_service_config_path }
      let(:object_under_test) { config }
      let(:expected_redirect_url) { urls.cloud_service_config_path }

      let(:valid_attributes) do
        {
          cloud_service_config: {
            cluster_builder_base_url: config.cluster_builder_base_url + ".updated",
            internal_auth_url: config.internal_auth_url + ".updated",
          }
        }
      end
      let(:invalid_attributes) do
        {cloud_service_config: {cluster_builder_base_url: -1}}
      end

      let(:param_key) { object_under_test.model_name.param_key }

      context "with valid parameters" do
        def send_request
          patch url_under_test,
            params: valid_attributes,
            headers: headers
        end

        it "updates the object under test" do
          expect {
            send_request
            object_under_test.reload
          }.to change(object_under_test, :updated_at)
        end

        it "redirects to the expected url" do
          send_request
          expect(response).to redirect_to(expected_redirect_url)
        end

        it "updates the expected attributes" do
          expected_changes = nil
          valid_attributes.stringify_keys[param_key].each do |key, value|
            if expected_changes.nil?
              expected_changes = change(object_under_test, key).to(value)
            else
              expected_changes = expected_changes.and change(object_under_test, key).to(value)
            end
          end

          expect {
            send_request
            object_under_test.reload
          }.to expected_changes
        end
      end

      context "with invalid parameters" do
        def send_request
          patch url_under_test,
            params: invalid_attributes,
            headers: headers
        end

        it "does not update the object under test" do
          expect {
            send_request
            object_under_test.reload
          }.not_to change(object_under_test, :updated_at)
        end

        it "renders an unprocessable entity response" do
          send_request
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end
  end
end
