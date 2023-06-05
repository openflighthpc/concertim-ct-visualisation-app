require 'rails_helper'

RSpec.describe "Api::V1::UsersControllers", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }

  describe "GET :index" do
    let(:url_under_test) { urls.api_v1_users_path }

    let(:parsed_body) { JSON.parse(response.body) }
    let(:parsed_users) { parsed_body }

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"

      context "when there are no other users" do
        include_examples "successful JSON response"

        it "includes a single admin user" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_users.length).to eq 1
          expect(parsed_users.first['id']).to eq authenticated_user.id
        end
      end

      context "when there is one other user" do
        let!(:other_user) { create(:user) }

        include_examples "successful JSON response"

        it "includes two users" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_users.length).to eq 2
        end

        it "includes the expected racks" do
          expected_ids = [authenticated_user.id, other_user.id].sort

          get url_under_test, headers: headers, as: :json

          retrieved_ids = parsed_users.map { |r| r["id"] }.sort
          expect(retrieved_ids).to eq expected_ids
        end
      end
    end

    context "when logged in as non-admin" do
      include_context "Logged in as non-admin"
      let!(:other_user) { create(:user) }

      include_examples "successful JSON response"

      it "includes the authenticated user" do
        get url_under_test, headers: headers, as: :json
        expect(parsed_users.length).to eq 1
        expect(parsed_users.first['id']).to eq authenticated_user.id
      end

      it "does not include other users" do
        get url_under_test, headers: headers, as: :json

        expect(parsed_users.map { |u| u['id'] }).not_to include other_user.id
      end
    end
  end

  describe "GET :current" do
    let(:url_under_test) { urls.current_api_v1_users_path }

    let(:parsed_body) { JSON.parse(response.body) }
    let(:parsed_user) { parsed_body }

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"
      let!(:other_user) { create(:user) }

      it "returns the authenticated user" do
        get url_under_test, headers: headers, as: :json
        expect(parsed_user['id']).to eq authenticated_user.id
      end
    end

    context "when logged in as non-admin" do
      include_context "Logged in as non-admin"
      let!(:other_user) { create(:user) }

      include_examples "successful JSON response"

      it "returns the authenticated user" do
        get url_under_test, headers: headers, as: :json
        expect(parsed_user['id']).to eq authenticated_user.id
      end
    end
  end

  describe "PATCH :update" do
    let(:url_under_test) { urls.api_v1_user_path(user) }
    let(:user) { create(:user, project_id: initial_project_id) }
    let(:initial_project_id) { nil }

    shared_examples "can set user's project_id" do
      include_examples "update generic JSON API endpoint examples" do
        before(:each) do
          expect(user.project_id).to be_blank
        end

        let(:object_under_test) { user }
        let(:valid_attributes) {
          {
            user: { project_id: SecureRandom.uuid }
          }
        }
        let(:invalid_attributes) {
          {
            user: { }
          }
        }
      end
    end

    shared_examples "can update user's project_id" do
      before(:each) { user.project_id = SecureRandom.uuid; user.save! }

      include_examples "update generic JSON API endpoint examples" do
        let(:object_under_test) { user }
        let(:valid_attributes) {
          {
            user: { project_id: SecureRandom.uuid }
          }
        }
        let(:invalid_attributes) {
          {
            user: { }
          }
        }
      end
    end

    shared_examples "cannot update user's project_id" do
      before(:each) { user.project_id = SecureRandom.uuid; user.save! }

      include_examples "cannot update generic JSON API endpoint examples" do
        let(:object_under_test) { user }
        let(:valid_attributes) {
          {
            user: { project_id: SecureRandom.uuid }
          }
        }
        let(:invalid_attributes) {
          {
            user: { }
          }
        }
      end
    end

    shared_examples "can unset user's project_id" do
      before(:each) { user.project_id = SecureRandom.uuid; user.save! }

      include_examples "update generic JSON API endpoint examples" do
        let(:object_under_test) { user }
        let(:valid_attributes) {
          {
            user: { project_id: nil }
          }
        }
        let(:invalid_attributes) {
          {
            user: { }
          }
        }
      end
    end

    shared_examples "cannot unset user's project_id" do
      before(:each) { user.project_id = SecureRandom.uuid; user.save! }

      include_examples "cannot update generic JSON API endpoint examples" do
        let(:object_under_test) { user }
        let(:valid_attributes) {
          {
            user: { project_id: nil }
          }
        }
        let(:invalid_attributes) {
          {
            user: { }
          }
        }
      end
    end

    context "when not logged in" do
      include_examples "unauthorised JSON response" do
        let(:request_method) { :patch }
      end
    end

    context "when logged in as updated user" do
      include_context "Logged in as non-admin"
      let(:user) { authenticated_user }
      it_behaves_like "can set user's project_id"
      it_behaves_like "cannot update user's project_id"
      it_behaves_like "cannot unset user's project_id"
    end

    context "when logged in as some other non-admin user" do
      include_context "Logged in as non-admin"
      include_examples "forbidden JSON response" do
        let(:request_method) { :patch }
      end
    end

    context "when logged in as admin user" do
      include_context "Logged in as admin"
      it_behaves_like "can set user's project_id"
      it_behaves_like "can update user's project_id"
      it_behaves_like "can unset user's project_id"
    end
  end
end
