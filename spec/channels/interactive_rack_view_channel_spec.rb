require "rails_helper"

RSpec.describe InteractiveRackViewChannel, type: :channel do
  let(:user)    { create(:user) }
  let(:env)     { instance_double('env') }
  let(:warden)  { instance_double('warden', user: user) }

  before do
      allow_any_instance_of(ApplicationCable::Connection).to receive(:env).and_return(env)
      allow(env).to receive(:[]).with('warden').and_return(warden)
      stub_connection current_user: user
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

  # TODO
  # add with rack
  # add with multiple racks
  # demonstrate unrelated rack not included
  # add with admin user

end
