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

RSpec.describe "Api::V1::UsersControllers", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }
  let(:param_key) { "user" }

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
          result = parsed_users.first
          expect(result['id']).to eq authenticated_user.id
          expect(result['root']).to eq true
          expect(result['name']).to eq authenticated_user.name
          expect(result['email']).to eq authenticated_user.email
        end
      end

      context "when there is one other user" do
        let!(:other_user) { create(:user) }

        include_examples "successful JSON response"

        it "includes two users" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_users.length).to eq 2
          result = parsed_users.first
          expect(result['id']).to eq other_user.id
          expect(result['root']).to eq false
          expect(result['name']).to eq other_user.name
          expect(result['email']).to eq other_user.email
        end

        it "includes the expected users" do
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
    let(:initial_value) { nil }

    %w( cloud_user_id ).each do |attr_under_test|

      let(:user) { create(:user, attr_under_test => initial_value) }

      shared_examples "can update user's #{attr_under_test}" do
        context "when first setting a user's #{attr_under_test}" do
          include_examples "update generic JSON API endpoint examples" do
            before(:each) do
              expect(user.send(attr_under_test)).to be_blank
            end

            let(:object_under_test) { user }
            let(:param_key) { "user" }
            let(:valid_attributes) {
              {
                user: { attr_under_test => SecureRandom.uuid }
              }
            }
            let(:invalid_attributes) {
              {
                user: { }
              }
            }
          end
        end

        context "when unsetting a user's #{attr_under_test}" do
          include_examples "update generic JSON API endpoint examples" do
            before(:each) { user.send("#{attr_under_test}=", SecureRandom.uuid); user.save! }

            let(:object_under_test) { user }
            let(:param_key) { "user" }
            let(:valid_attributes) {
              {
                user: { attr_under_test => nil }
              }
            }
            let(:invalid_attributes) {
              {
                user: { }
              }
            }
          end
        end

        context "when updating user's #{attr_under_test}" do
          include_examples "update generic JSON API endpoint examples" do
            before(:each) { user.send("#{attr_under_test}=", SecureRandom.uuid); user.save! }

            let(:object_under_test) { user }
            let(:param_key) { "user" }
            let(:valid_attributes) {
              {
                user: { attr_under_test => SecureRandom.uuid }
              }
            }
            let(:invalid_attributes) {
              {
                user: { }
              }
            }
          end
        end
      end

      shared_examples "cannot update user's #{attr_under_test}" do
        context "when first setting a user's #{attr_under_test}" do
          include_examples "cannot update generic JSON API endpoint examples" do
            before(:each) do
              expect(user.send(attr_under_test)).to be_blank
            end

            let(:object_under_test) { user }
            let(:param_key) { "user" }
            let(:valid_attributes) {
              {
                user: { attr_under_test => SecureRandom.uuid }
              }
            }
            let(:invalid_attributes) {
              {
                user: { }
              }
            }
          end
        end

        context "when unsetting a user's #{attr_under_test}" do
          include_examples "cannot update generic JSON API endpoint examples" do
            before(:each) { user.send("#{attr_under_test}=", SecureRandom.uuid); user.save! }
            let(:object_under_test) { user }
            let(:param_key) { "user" }
            let(:valid_attributes) {
              {
                user: { attr_under_test => nil }
              }
            }
            let(:invalid_attributes) {
              {
                user: { }
              }
            }
          end
        end

        context "when updating user's #{attr_under_test}" do
          include_examples "cannot update generic JSON API endpoint examples" do
            before(:each) { user.send("#{attr_under_test}=", SecureRandom.uuid); user.save! }

            let(:object_under_test) { user }
            let(:param_key) { "user" }
            let(:valid_attributes) {
              {
                user: { attr_under_test => SecureRandom.uuid }
              }
            }
            let(:invalid_attributes) {
              {
                user: { }
              }
            }
          end
        end
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
      it_behaves_like "cannot update user's cloud_user_id"
    end

    context "when logged in as some other non-admin user" do
      include_context "Logged in as non-admin"
      include_examples "forbidden JSON response" do
        let(:request_method) { :patch }
      end
    end

    context "when logged in as admin user" do
      include_context "Logged in as admin"
      it_behaves_like "can update user's cloud_user_id"
    end
  end

  describe "DELETE :destroy" do
    before(:each) do
      # Ensure the users are created before the test runs.  Else the `change`
      # expectation may not work correctly.
      authenticated_user
      user_to_delete
      create(:cloud_service_config)
    end

    let(:url_under_test) { urls.api_v1_user_path(user_to_delete) }
    let(:user_to_delete) { create(:user) }

    def send_request
      delete url_under_test,
        headers: headers,
        as: :json
    end

    context "when not logged in" do
      include_context "Not logged in"
      include_examples "unauthorised JSON response" do
        let(:request_method) { :delete }
      end
    end

    context "when logged in as a non-admin user" do
      include_context "Logged in as non-admin"
      include_examples "forbidden JSON response" do
        let(:request_method) { :delete }
      end
    end

    context "when logged in as admin user" do
      include_context "Logged in as admin"

      context "when user to delete is an admin" do
        let(:user_to_delete) { create(:user, :admin) }
        include_examples "forbidden JSON response" do
          let(:request_method) { :delete }
        end
      end

      context "when user to delete is a non-admin" do
        let(:user_to_delete) { create(:user) }

        it "deletes the user" do
          expect(user_to_delete.deleted_at).to be_nil
          send_request
          user_to_delete.reload
          expect(user_to_delete.deleted_at).not_to be_nil
          expect(UserDeletionJob).to have_been_enqueued
        end
      end

      context "when user to delete is a non-admin with racks" do
        let(:user_to_delete) { create(:user, :member_of_empty_rack) }

        it "does not delete the user" do
          expect {
            send_request
          }.not_to change(User, :count)
        end

        it "responds with a 422 unprocessable_entity" do
          send_request
          expect(response).to have_http_status :unprocessable_entity
        end

        it "contains the expected error message" do
          send_request
          error_document = JSON.parse(response.body)
          expect(error_document).to have_key "errors"
          expect(error_document["errors"].length).to eq 1
          expect(error_document["errors"][0]["title"]).to eq "Unprocessable Content"
          expect(error_document["errors"][0]["description"]).to match /Cannot delete user as they have\b.*\bracks/i
        end
      end
    end
  end
end
