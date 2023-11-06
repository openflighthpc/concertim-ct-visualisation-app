class InteractiveRackViewChannel < ApplicationCable::Channel
  after_subscribe :transmit_all_racks, unless: :subscription_rejected?

  # If we ever change to a different stream (e.g. by project id) we will need to add some authorization/ rejection
  # logic here. At the moment we rely on connection obtaining a valid user & closing the connection if none.
  def subscribed
    stream_for current_user
    ensure_confirmation_sent # without this, after_subscribe may run before confirmation is sent
  end

  private

  def transmit_all_racks
    all_racks = Irv::HwRackServices::Index.call(current_user)
    # all_racks = {Racks: {Rack: []}}
    all_racks[:action] = "latest_full_data"
    transmit(all_racks)
  end
end
