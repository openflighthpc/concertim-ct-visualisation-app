class InteractiveRackViewChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user

    all_racks = Irv::HwRackServices::Index.call(current_user)
    # all_racks = {Racks: {Rack: []}}
    all_racks[:action] = "latest_full_data"
    transmit(all_racks)
  end
end
