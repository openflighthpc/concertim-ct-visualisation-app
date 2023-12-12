class BroadcastRackChangeJob < ApplicationJob
  queue_as :default

  def perform(rack_id, user_id, action)
    if action == "deleted"
      msg = { action: action, rack: {id: rack_id}}
    else
      msg = rack_content(rack_id, action, user_id)
    end
    User.where(root: true).or(User.where(id: user_id)).each do |user|
      InteractiveRackViewChannel.broadcast_to(user, msg)
    end
  end

  def rack_content(rack_id, action, user_id)
   user = User.find(user_id)
   { action: action, rack: Irv::HwRackServices::Show.call(user, rack_id) }
  end
end
