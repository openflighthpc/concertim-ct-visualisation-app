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

RSpec.describe BroadcastRackChangeJob, type: :job do
  let(:user) { create(:user, :as_team_member, team: team) }
  let(:team) { create(:team) }
  let(:template) { create(:template, :rack_template) }
  let(:device_template) { create(:template, :device_template) }
  let!(:rack) { create(:rack, team: team, template: template) }
  let!(:device) { create(:device, chassis: chassis) }
  let(:chassis) { create(:chassis, location: location, template: device_template) }
  let(:location) { create(:location, rack: rack) }
  subject { BroadcastRackChangeJob.perform_now(rack.id, team.id, action) }

  context 'rack deletion' do
    let(:action) { "deleted" }

    it 'broadcasts action and rack id to user irv channel' do
      msg = { action: "deleted", rack: {id: rack.id} }
      expect { subject }.to have_broadcasted_to(user).from_channel(InteractiveRackViewChannel).with(msg)
    end
  end

  shared_examples 'rack data broadcast' do
    it 'broadcasts rack data to user irv channel' do
      expected = ->(data) {
        expect(data["action"]).to eq action
        rack_data = data["rack"]
        expect(rack_data.present?).to be true
        expect(rack_data["owner"]["id"]).to eq rack.team.id.to_s
        expect(rack_data["template"]["name"]).to eq rack.template.name
        expect(rack_data["Chassis"]["Slots"]["Machine"]["id"]).to eq device.id.to_s
        expect(rack_data["id"]).to eq rack.id.to_s
        expect(rack_data["name"]).to eq rack.name
        expect(rack_data["cost"]).to eq "$0.00"
        expect(rack_data["teamRole"]).to eq "member"
      }

      expect { subject }.to have_broadcasted_to(user).from_channel(InteractiveRackViewChannel).with(nil, &expected)
    end
  end

  context 'rack created' do
    let(:action) { "added" }

    include_examples 'rack data broadcast'
  end

  context 'rack updated' do
    let(:action) { "updated" }

    include_examples 'rack data broadcast'
  end

end
