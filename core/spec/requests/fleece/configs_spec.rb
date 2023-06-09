require 'rails_helper'

RSpec.describe "Fleece::Configs", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }

  describe "GET :show" do
    let(:url_under_test) { urls.fleece_config_path }
    before(:each) { create(:fleece_config) }

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
    let(:url_under_test) { urls.new_fleece_config_path }

    context "when logged in as admin" do
      include_context "Logged in as admin"

      context "when there is not yet a fleece config" do
        include_examples "successful HTML response"
      end

      context "when there is already a fleece config" do
        before(:each) { create(:fleece_config) }

        it "redirects to the edit page" do
          get url_under_test, headers: headers
          expect(response).to redirect_to urls.edit_fleece_config_path
        end
      end
    end
  end

  describe "GET :edit" do
    let(:url_under_test) { urls.edit_fleece_config_path }

    context "when logged in as admin" do
      include_context "Logged in as admin"

      context "when there is not yet a fleece config" do
        before(:each) { expect(Fleece::Config.count).to eq 0 }

        it "redirects to the new page" do
          get url_under_test, headers: headers
          expect(response).to redirect_to urls.new_fleece_config_path
        end
      end

      context "when there is already a fleece config" do
        before(:each) { create(:fleece_config) }

        include_examples "successful HTML response"
      end
    end
  end

  describe "POST :create" do
    context "when logged in as admin" do
      include_context "Logged in as admin"

      let(:url_under_test) { urls.fleece_config_path }
      let(:model_under_test) { Fleece::Config }
      let(:expected_redirect_url) { urls.fleece_config_path }

      let(:valid_attributes) do
        {fleece_config: attributes_for(:fleece_config)}
      end
      let(:invalid_attributes) do
        {fleece_config: {host_ip: -1}}
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

      let!(:fleece_config) { create(:fleece_config) }

      let(:url_under_test) { urls.fleece_config_path }
      let(:object_under_test) { fleece_config }
      let(:expected_redirect_url) { urls.fleece_config_path }

      let(:valid_attributes) do
        {
          fleece_config: {
            host_name: fleece_config.host_name + ".updated",
            domain_name: fleece_config.domain_name + ".updated",
          }
        }
      end
      let(:invalid_attributes) do
        {fleece_config: {host_ip: -1}}
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

  describe "POST :send_config" do
    let(:url_under_test) { urls.send_fleece_config_path }

    context "when not logged in" do
      include_examples "unauthorised HTML request" do
        let(:request_method) { :post }
      end
    end

    context "when logged in as non-admin" do
      include_context "Logged in as non-admin"
      include_examples "forbidden HTML request" do
        let(:request_method) { :post }
      end
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"

      context "when there is not a configuration" do
        before(:each) { Fleece::Config.destroy_all }

        it "does not perform the job" do
          result = Fleece::PostConfigJob::Result.new(true, nil)
          allow(Fleece::PostConfigJob).to receive(:perform_now).and_return(result)

          post url_under_test, headers: headers
          expect(Fleece::PostConfigJob).not_to have_received(:perform_now)
        end

        it "displays an error message to the user" do
          post url_under_test, headers: headers
          expect(flash[:alert]).to match /Unable to send/
        end
      end

      context "when there is a configuration" do
        let!(:config) { create(:fleece_config) }
        let(:result) { Fleece::PostConfigJob::Result.new(success, error_message) }
        let(:success) { true }
        let(:error_message) { nil }

        before(:each) do 
          allow(Fleece::PostConfigJob).to receive(:perform_now).and_return(result)
        end

        it "performs the job now" do
          post url_under_test, headers: headers
          expect(Fleece::PostConfigJob).to have_received(:perform_now).with(config).once
        end

        context "when the job is successful" do
          it "displays an info message to the user" do
            post url_under_test, headers: headers
            expect(flash[:success]).to match /\bconfig.*\bsent\b/
          end
        end

        context "when the job is unsuccessful" do
          let(:success) { false }
          let(:error_message) { "oopsie daisy" }

          it "displays an error message to the user" do
            post url_under_test, headers: headers
            expect(flash[:alert]).to match error_message
          end
        end
      end
    end
  end
end
