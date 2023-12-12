require 'rails_helper'

RSpec.describe DisconnectIrvWebsocketJob, type: :job do
  let(:user)    { create(:user) }
  let(:server) { ActionCable.server }

  it "sends disconnect message" do
    expect(server).to receive(:broadcast).once.with("action_cable/#{user.to_gid_param}", {:type=>"disconnect"})
    DisconnectIrvWebsocketJob.perform_now(user.id)
  end

  # Ideally we would also test any relevant websockets have been closed, but (after significant investigation)
  # I'm not sure how/ if it's feasible to do this here - perhaps with front end tests.
end
