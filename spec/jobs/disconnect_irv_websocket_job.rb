require 'rails_helper'

RSpec.describe DisconnectIrvWebsocketJob, type: :job do
  describe ApplicationCable::Connection, type: :channel do

    let(:user)    { create(:user) }
    let(:env)     { instance_double('env') }
    let(:warden)  { instance_double('warden', user: user) }

    before do
      allow_any_instance_of(ApplicationCable::Connection).to receive(:env).and_return(env)
      allow(env).to receive(:[]).with('warden').and_return(warden)
    end

    it "successfully connects" do
      connect "/cable", headers: { "X-USER-ID" => user.id }
      expect(connect.current_user.id).to eq user.id
      DisconnectIrvWebsocketJob.perform_now(user.id)
      # how to check outcome?
    end
  end
end
