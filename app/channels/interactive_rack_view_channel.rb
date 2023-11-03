class InteractiveRackViewChannel < ApplicationCable::Channel
  after_subscribe :transmit_all_racks, unless: :subscription_rejected?

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
