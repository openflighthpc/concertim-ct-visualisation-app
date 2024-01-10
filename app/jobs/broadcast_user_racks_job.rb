class BroadcastUserRacksJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    all_racks = Irv::HwRackServices::Index.call(user)
    all_racks[:action] = "latest_full_data"
    InteractiveRackViewChannel.broadcast_to(user, all_racks)
  end
end
