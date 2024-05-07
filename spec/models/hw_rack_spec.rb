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

RSpec.describe HwRack, type: :model do
  subject { rack }
  let!(:template) { create(:template, :rack_template) }
  let(:rack) { create(:rack, team: team, template: template) }
  let!(:team) { create(:team) }

  describe 'validations' do
    it "is valid with valid attributes" do
      rack = described_class.new(
        template: template,
        team: team,
        status: 'IN_PROGRESS',
        cost: 99.99,
        order_id: 42,
      )
      expect(rack).to be_valid
    end

    it "is not valid without a name" do
      subject.name = nil
      expect(subject).to have_error(:name, :blank)
    end

    it "is not valid without a u_height" do
      subject.u_height = nil
      expect(subject).to have_error(:u_height, :not_a_number)
    end

    it "is not valid without a u_depth" do
      subject.u_depth = nil
      expect(subject).to have_error(:u_depth, :not_a_number)
    end

    it "is not valid with nil metadata" do
      subject.metadata = nil
      expect(subject).to have_error(:metadata, "Must be an object")
    end

    it "is valid with blank metadata" do
      subject.metadata = {}
      expect(subject).to be_valid
    end

    it "is not valid without a template" do
      subject.template = nil
      expect(subject).to have_error(:template, :blank)
    end

    it "is not valid without a team" do
      subject.team = nil
      expect(subject).to have_error(:team, :blank)
    end

    it "must have a unique name" do
      new_rack = build(:rack, team: team, template: template, name: subject.name)
      expect(new_rack).to have_error(:name, :taken)
    end

    it "can duplicate names for racks belonging to other teams" do
      new_team = create(:team)
      new_rack = build(:rack, team: new_team, template: template, name: subject.name)
      expect(new_rack).not_to have_error(:name, :taken)
    end

    it "must be higher than highest node" do
      # Changing the height of a rack is only allowed if the new height is
      # sufficiently large to accommodate all of the nodes it contains.
      skip "implement this when we have device factories et al"
    end

    it "is not vaild without a status" do
      subject.status = nil
      expect(subject).to have_error(:status, :blank)
    end

    it "is not vaild with an invalid status" do
      subject.status = "SNAFU"
      expect(subject).to have_error(:status, :inclusion)
    end

    it "is not valid with a negative cost" do
      subject.cost = -99
      expect(subject).to have_error(:cost, :greater_than_or_equal_to)
    end

    describe "order_id" do
      it "is not valid without an order_id" do
        subject.order_id = nil
        expect(subject).to have_error(:order_id, :blank)
      end

      it "must have a unique order id" do
        new_rack = build(:rack, team: team, template: template, order_id: subject.order_id)
        expect(new_rack).to have_error(:order_id, :taken)
      end
    end
  end

  describe "defaults" do
    before(:each) { HwRack.destroy_all }

    context "when there are no other racks" do
      it "defaults height to 42" do
        rack = HwRack.new(u_height: nil, team: team)
        expect(rack.u_height).to eq 42
      end

      it "defaults name to Rack-1" do
        rack = HwRack.new(team: team)
        expect(rack.name).to eq "Rack-1"
      end
    end

    context "when there are other racks for other teams" do
      let(:other_team) { create(:team) }

      let!(:existing_rack) {
        create(:rack, u_height: 24, name: 'MyRack-2', template: template, team: other_team)
      }

      it "defaults height to 42" do
        rack = HwRack.new(u_height: nil, team: team)
        expect(rack.u_height).to eq 42
      end

      it "defaults name to Rack-1" do
        rack = HwRack.new(team: team)
        expect(rack.name).to eq "Rack-1"
      end
    end

    context "when there are other racks for this team" do
      let!(:existing_rack) {
        create(:rack, u_height: 24, name: 'MyRack-2', template: template, team: team)
      }

      it "defaults height to existing racks height" do
        rack = HwRack.new(u_height: nil, team: team)
        expect(rack.u_height).to eq 24
      end

      it "defaults name to increment of existing racks name" do
        rack = HwRack.new(team: team)
        expect(rack.name).to eq 'MyRack-3'
      end
    end
  end

  describe "broadcast changes" do
    let!(:user) { create(:user, :as_team_member, team: team) }

    shared_examples 'rack details' do
      it 'broadcasts rack details' do
        expect { subject }.to have_broadcasted_to(user).from_channel(InteractiveRackViewChannel).with { |data|
          expect(data["action"]).to eq action
          rack_data = data["rack"]
          expect(rack_data.present?).to be true
          expect(rack_data["owner"]["id"]).to eq rack.team.id.to_s
          expect(rack_data["template"]["name"]).to eq rack.template.name
          expect(rack_data["id"]).to eq rack.id.to_s
          expect(rack_data["name"]).to eq rack.name
          expect(rack_data["cost"]).to eq "$0.00"
        }
      end
    end

    context 'created' do
      let(:action) { "added" }
      subject { rack }

      include_examples 'rack details'
    end

    context 'updated' do
      let(:action) { "modified" }
      let!(:rack) { create(:rack, team: team, template: template) }
      subject do
        rack.name = "new_name"
        rack.save!
      end

      include_examples 'rack details'
    end

    context 'deleted' do
      let!(:rack) { create(:rack, team: team, template: template) }
      subject { rack.destroy! }

      it 'broadcasts deleted rack' do
        msg = { action: "deleted", rack: {id: rack.id} }
        expect { subject }.to have_broadcasted_to(user).from_channel(InteractiveRackViewChannel).with(msg)
      end

      context 'with device' do
        let(:device_template) { create(:template, :device_template) }
        let!(:device) { create(:device, chassis: chassis) }
        let(:chassis) { create(:chassis, location: location, template: device_template) }
        let(:location) { create(:location, rack: rack) }

        it 'broadcasts rack deletion only' do
          msg = { action: "deleted", rack: {id: rack.id} }
          expect { subject }.to have_broadcasted_to(user).from_channel(InteractiveRackViewChannel).once.with(msg)
        end
      end
    end
  end
end
