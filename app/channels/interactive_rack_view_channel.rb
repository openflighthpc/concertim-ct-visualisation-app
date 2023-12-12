class InteractiveRackViewChannel < ApplicationCable::Channel
  # If we ever change to a different stream (e.g. by project id) we will need to add some authorization/ rejection
  # logic here. At the moment we rely on connection obtaining a valid user & closing the connection if none.
  def subscribed
    stream_for current_user
  end

  def all_racks_sync
    all_racks = Irv::HwRackServices::Index.call(current_user)
    all_racks[:action] = "latest_full_data"
    transmit(all_racks)
  end
end
