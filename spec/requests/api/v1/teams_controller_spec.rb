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
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

require 'rails_helper'

RSpec.describe "Api::V1::TeamsControllers", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }
  let(:param_key) { "team" }

  describe "GET :index" do
    let(:url_under_test) { urls.api_v1_teams_path }

    let(:parsed_body) { JSON.parse(response.body) }
    let(:parsed_teams) { parsed_body }

    context "when not logged in" do
      include_examples "unauthorised JSON response"
    end

    context "when logged in as admin" do
      include_context "Logged in as admin"

      context "when there are no teams" do
        include_examples "successful JSON response"

        it "includes no teams" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_teams.length).to eq 0
        end
      end

      context "when there is one team" do
        let!(:team) { create(:team) }

        include_examples "successful JSON response"

        it "includes one team" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_teams.length).to eq 1
          result = parsed_teams.first
          expect(result['id']).to eq team.id
          expect(result['name']).to eq team.name
          expect(result['cost']).to eq team.cost.to_s
        end
      end

      context "when there are multiple teams" do
        let!(:team) { create(:team, name: "Aardvarks") }
        let!(:another_team) { create(:team, name: "Zebras") }

        include_examples "successful JSON response"

        it "includes two teams" do
          get url_under_test, headers: headers, as: :json
          expect(parsed_teams.length).to eq 2
          result = parsed_teams.last
          expect(result['id']).to eq another_team.id
          expect(result['name']).to eq another_team.name
          expect(result['cost']).to eq another_team.cost.to_s
        end

        it "includes the expected teams" do
          expected_ids = [team.id, another_team.id].sort

          get url_under_test, headers: headers, as: :json

          retrieved_ids = parsed_teams.map { |r| r["id"] }.sort
          expect(retrieved_ids).to eq expected_ids
        end
      end
    end

    context "when logged in as non-admin" do
      include_context "Logged in as non-admin"
      include_examples "successful JSON response"

      let!(:team) { create(:team) }
      let!(:another_team) { create(:team) }
      let!(:team_role) { create(:team_role, user: authenticated_user, team: team) }

      it "includes team team is a part of" do
        get url_under_test, headers: headers, as: :json
        expect(parsed_teams.length).to eq 1
        expect(parsed_teams.first['id']).to eq team.id
      end

      it "does not include other teams" do
        get url_under_test, headers: headers, as: :json

        expect(parsed_teams.map { |u| u['id'] }).not_to include another_team.id
      end
    end
  end

  describe "PATCH :update" do
    let(:url_under_test) { urls.api_v1_team_path(team) }
    let(:initial_value) { nil }

    %w( project_id billing_acct_id ).each do |attr_under_test|

      let(:team) { create(:team, attr_under_test => initial_value) }

      shared_examples "can update team's #{attr_under_test}" do
        context "when first setting a team's #{attr_under_test}" do
          include_examples "update generic JSON API endpoint examples" do
            before(:each) do
              expect(team.send(attr_under_test)).to be_blank
            end

            let(:object_under_test) { team }
            let(:param_key) { "team" }
            let(:valid_attributes) {
              {
                team: { attr_under_test => SecureRandom.uuid }
              }
            }
            let(:invalid_attributes) {
              {
                team: { }
              }
            }
          end
        end

        context "when unsetting a team's #{attr_under_test}" do
          include_examples "update generic JSON API endpoint examples" do
            before(:each) { team.send("#{attr_under_test}=", SecureRandom.uuid); team.save! }

            let(:object_under_test) { team }
            let(:param_key) { "team" }
            let(:valid_attributes) {
              {
                team: { attr_under_test => nil }
              }
            }
            let(:invalid_attributes) {
              {
                team: { }
              }
            }
          end
        end

        context "when updating team's #{attr_under_test}" do
          include_examples "update generic JSON API endpoint examples" do
            before(:each) { team.send("#{attr_under_test}=", SecureRandom.uuid); team.save! }

            let(:object_under_test) { team }
            let(:param_key) { "team" }
            let(:valid_attributes) {
              {
                team: { attr_under_test => SecureRandom.uuid }
              }
            }
            let(:invalid_attributes) {
              {
                team: { }
              }
            }
          end
        end
      end

      shared_examples "cannot update team's #{attr_under_test}" do
        context "when first setting a team's #{attr_under_test}" do
          include_examples "cannot update generic JSON API endpoint examples" do
            before(:each) do
              expect(team.send(attr_under_test)).to be_blank
            end

            let(:object_under_test) { team }
            let(:param_key) { "team" }
            let(:valid_attributes) {
              {
                team: { attr_under_test => SecureRandom.uuid }
              }
            }
            let(:invalid_attributes) {
              {
                team: { }
              }
            }
          end
        end

        context "when unsetting a team's #{attr_under_test}" do
          include_examples "cannot update generic JSON API endpoint examples" do
            before(:each) { team.send("#{attr_under_test}=", SecureRandom.uuid); team.save! }
            let(:object_under_test) { team }
            let(:param_key) { "team" }
            let(:valid_attributes) {
              {
                team: { attr_under_test => nil }
              }
            }
            let(:invalid_attributes) {
              {
                team: { }
              }
            }
          end
        end

        context "when updating team's #{attr_under_test}" do
          include_examples "cannot update generic JSON API endpoint examples" do
            before(:each) { team.send("#{attr_under_test}=", SecureRandom.uuid); team.save! }

            let(:object_under_test) { team }
            let(:param_key) { "team" }
            let(:valid_attributes) {
              {
                team: { attr_under_test => SecureRandom.uuid }
              }
            }
            let(:invalid_attributes) {
              {
                team: { }
              }
            }
          end
        end
      end
    end

    shared_examples "can update team's cost" do
      include_examples "update generic JSON API endpoint examples" do
        let(:object_under_test) { team }
        let(:param_key) { "team" }
        let(:valid_attributes) {
          {
            team: { cost: 100.001 }
          }
        }
        let(:invalid_attributes) {
          {
            team: { }
          }
        }
      end
    end

    shared_examples "cannot update team's cost" do
      include_examples "cannot update generic JSON API endpoint examples" do
        let(:object_under_test) { team }
        let(:param_key) { "team" }
        let(:valid_attributes) {
          {
            team: { cost: 100.001 }
          }
        }
        let(:invalid_attributes) {
          {
            team: { }
          }
        }
      end
    end

    %w( billing_period_start billing_period_end ).each do |attr_under_test|
      shared_examples "can update team's #{attr_under_test}" do
        before(:each) do
          team.billing_period_start = Date.current - 1.month
          team.billing_period_end = Date.current
          team.save!
        end

        include_examples "update generic JSON API endpoint examples" do
          let(:object_under_test) { team }
          let(:param_key) { "team" }
          let(:valid_attributes) {
            {
              team: { attr_under_test => team.send(attr_under_test) + 1.day}
            }
          }
          let(:invalid_attributes) {
            {
              team: { }
            }
          }
        end
      end

      shared_examples "cannot update team's #{attr_under_test}" do
        before(:each) do
          team.billing_period_start = Date.current - 1.month
          team.billing_period_end = Date.current
          team.save!
        end
        include_examples "cannot update generic JSON API endpoint examples" do
          let(:object_under_test) { team }
          let(:param_key) { "team" }
          let(:valid_attributes) {
            {
              team: { attr_under_test => team.send(attr_under_test) + 1.day}
            }
          }
          let(:invalid_attributes) {
            {
              team: { }
            }
          }
        end
      end
    end

    context "when not logged in" do
      include_examples "unauthorised JSON response" do
        let(:request_method) { :patch }
      end
    end

    context "when logged in as team member" do
      include_context "Logged in as non-admin"
      let(:team) { create(:team) }
      let!(:team_role) { create(:team_role, team: team, user: authenticated_user, role: "member") }
      include_examples "forbidden JSON response" do
        let(:request_method) { :patch }
      end
    end

    context "when logged in as team admin user" do
      include_context "Logged in as non-admin"
      let(:team) { create(:team) }
      let!(:team_role) { create(:team_role, team: team, user: authenticated_user, role: "admin") }
      include_examples "forbidden JSON response" do
        let(:request_method) { :patch }
      end
    end

    context "when logged in as some user not part of team" do
      include_context "Logged in as non-admin"
      let(:team) { create(:team) }
      include_examples "forbidden JSON response" do
        let(:request_method) { :patch }
      end
    end

    context "when logged in as super admin user" do
      include_context "Logged in as admin"
      it_behaves_like "can update team's project_id"
      it_behaves_like "can update team's cost"
      it_behaves_like "can update team's billing_acct_id"
      it_behaves_like "can update team's billing_period_start"
      it_behaves_like "can update team's billing_period_end"
    end
  end

  describe "DELETE :destroy" do
    before(:each) do
      # Ensure the teams are created before the test runs.  Else the `change`
      # expectation may not work correctly.
      authenticated_user
      team_to_delete
      create(:cloud_service_config)
    end

    let(:url_under_test) { urls.api_v1_team_path(team_to_delete) }
    let(:team_to_delete) { create(:team) }

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

    context "when logged in as a non super-admin user" do
      include_context "Logged in as non-admin"
      include_examples "forbidden JSON response" do
        let(:request_method) { :delete }
      end
    end

    context "when logged in as super admin" do
      include_context "Logged in as admin"

      context "when team has no racks" do
        let(:team_to_delete) { create(:team) }

        it "deletes the team" do
          expect(team_to_delete.deleted_at).to be_nil
          send_request
          team_to_delete.reload
          expect(team_to_delete.deleted_at).not_to be_nil
          expect(DeleteTeamJob).to have_been_enqueued
        end
      end

      context "when team to delete is has racks" do
        let(:team_to_delete) { create(:team, :with_empty_rack) }

        it "does not delete the team" do
          expect {
            send_request
          }.not_to change(Team, :count)
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
          expect(error_document["errors"][0]["description"]).to match /Cannot delete team as they have\b.*\bracks/i
        end
      end
    end
  end
end
