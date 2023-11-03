class InteractiveRackViewChannel < ApplicationCable::Channel
  after_subscribe :transmit_all_racks, unless: :subscription_rejected?

  def subscribed
    stream_for current_user
  end

  private

  def transmit_all_racks
    all_racks = Irv::HwRackServices::Index.call(current_user)
    # all_racks = {Racks: {Rack: []}}
    all_racks[:action] = "latest_full_data"
    InteractiveRackViewChannel.broadcast_to(current_user, all_racks)
  end
end
