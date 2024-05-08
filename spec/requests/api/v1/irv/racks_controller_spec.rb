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

RSpec.describe "Api::V1::Irv::RacksControllers", type: :request do
  let(:headers) { {} }
  let(:urls) { Rails.application.routes.url_helpers }

  shared_examples 'requests' do
    describe "GET :index" do
      let(:url_under_test) { urls.api_v1_irv_racks_path(params) }

      context "when not logged in" do
        include_examples "unauthorised JSON response"
      end

      context "when logged in as admin" do
        include_context "Logged in as admin"

        context "when there are no racks" do
          let(:parsed_body) { JSON.parse(response.body) }
          let(:parsed_racks) { parsed_body["Racks"]["Rack"] }

          include_examples "successful JSON response"

          it "includes zero racks" do
            get url_under_test, headers: headers, as: :json
            expect(parsed_racks).to be_a Array
            expect(parsed_racks).to be_empty
          end
        end

        context "when there is one rack" do
          let!(:template) { create(:template, :rack_template) }
          let!(:rack) { create(:rack, template: template, cost: 9.99) }

          let(:parsed_body) { JSON.parse(response.body) }
          let(:parsed_racks) { parsed_body["Racks"]["Rack"] }

          include_examples "successful JSON response"

          it "includes one rack in an array" do
            get url_under_test, headers: headers, as: :json
            expect(parsed_racks).to be_a Array
            expect(parsed_racks).not_to be_nil
          end

          it "has the correct attributes" do
            get url_under_test, headers: headers, as: :json
            parsed_rack = parsed_racks.first
            expect(parsed_rack["id"]).to eq rack.id
            expect(parsed_rack["name"]).to eq rack.name
            expect(parsed_rack["uHeight"].to_i).to eq rack.u_height
            expect(parsed_rack["cost"]).to eq "$9.99"
            expect(parsed_rack["teamRole"]).to eq "superAdmin"
          end

          it "includes the rack's template" do
            get url_under_test, headers: headers, as: :json
            expected_template = {
              height: (strings? ? template.height.to_s : template.height),
              depth: (strings? ? template.depth.to_s : template.depth),
              name: template.name,
            }.stringify_keys
            expect(parsed_racks.first["template"].slice(*expected_template.keys)).to eq expected_template
          end

          it "includes the rack's owner" do
            get url_under_test, headers: headers, as: :json
            expected_owner = {
              id: (strings? ? rack.team.id.to_s : rack.team.id),
              name: rack.team.name
            }.stringify_keys
            expect(parsed_racks.first["owner"].slice(*expected_owner.keys)).to eq expected_owner
          end
        end

        context "when there are two racks" do
          let!(:template) { create(:template, :rack_template) }
          let!(:racks) { create_list(:rack, 2, template: template) }

          let(:parsed_body) { JSON.parse(response.body) }
          let(:parsed_racks) { parsed_body["Racks"]["Rack"] }

          include_examples "successful JSON response"

          it "includes two racks" do
            get url_under_test, headers: headers, as: :json
            expect(parsed_racks).to be_a Array
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
  end

  context 'slow version' do
    let(:params) { {slow: true} }
    let(:strings?) { false }

    include_examples 'requests'
  end

  context 'non slow version' do
    let(:params) { nil }
    let(:strings?) { true }
    
    include_examples 'requests'
  end
end
