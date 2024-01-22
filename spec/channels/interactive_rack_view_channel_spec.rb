require "rails_helper"

RSpec.describe InteractiveRackViewChannel, type: :channel do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:active_user) { user }
  let(:env) { instance_double('env') }
  let(:warden) { instance_double('warden', user: user) }
  let!(:template) { create(:template, :rack_template) }

  before do
    allow_any_instance_of(ApplicationCable::Connection).to receive(:env).and_return(env)
    allow(env).to receive(:[]).with('warden').and_return(warden)
    stub_connection current_user: active_user
  end

  it "subscribes to a stream" do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(user)
  end

  it "transmit rack data for user when requested" do
    subscribe

    perform :all_racks_sync

    expected = {"Racks"=>{"Rack"=>[]}, "action"=>"latest_full_data"}
    assert_equal(expected, transmissions.last)
  end

  context 'with rack' do
    let!(:rack) { create(:rack, team: team, template: template) }
    let!(:team_role) { create(:team_role, team: team, user: user) }
    let(:device_template) { create(:template, :device_template) }
    let!(:device) { create(:device, chassis: chassis) }
    let(:chassis) { create(:chassis, location: location, template: device_template) }
    let(:location) { create(:location, rack: rack) }

    it 'includes rack details' do
      subscribe

      perform :all_racks_sync

      data = transmissions.last
      expect(data["action"]).to eq "latest_full_data"
      check_rack_data([rack], data)
    end

    context 'with multiple racks' do
      let!(:another_rack) { create(:rack, team: team, template: template) }
      let!(:different_team) { create(:team) }
      let!(:different_user_rack) { create(:rack, team: different_team, template: template) }

      it 'includes all racks for user' do
        subscribe

        perform :all_racks_sync

        data = transmissions.last
        expect(data["action"]).to eq "latest_full_data"
        expect(data["Racks"]["Rack"].length).to eq 2

        check_rack_data([rack, another_rack], data)
      end

      context 'admin user' do
        let(:admin) { create(:user, :admin) }
        let(:active_user) { admin }

        it 'includes details of all racks' do
          subscribe

          perform :all_racks_sync

          data = transmissions.last
          expect(data["action"]).to eq "latest_full_data"
          expect(data["Racks"]["Rack"].length).to eq 3

          check_rack_data([rack, another_rack, different_user_rack], data)
        end
      end
    end

    def check_rack_data(racks, data)
      racks.each_with_index do |r, index|
        rack_data = data["Racks"]["Rack"][index]
        expect(rack_data["id"]).to eq r.id.to_s
        expect(rack_data["name"]).to eq r.name
        expect(rack_data["uHeight"]).to eq r.u_height.to_s
        expect(rack_data["buildStatus"]).to eq r.status
        expect(rack_data["owner"]["id"]).to eq r.team.id.to_s
        expect(rack_data["template"]["id"]).to eq r.template.id.to_s
        if r.devices.exists?
          expect(rack_data["Chassis"]["Slots"]["Machine"]["id"]).to eq r.devices.last.id.to_s
        end
      end
    end
  end
end
