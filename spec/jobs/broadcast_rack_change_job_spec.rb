require 'rails_helper'

RSpec.describe BroadcastRackChangeJob, type: :job do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let!(:team_role) { create(:team_role, team: team, user: user) }
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
