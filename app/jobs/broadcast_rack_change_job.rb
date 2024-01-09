class BroadcastRackChangeJob < ApplicationJob
  queue_as :default

  def perform(rack_id, team_id, action)
    if action == "deleted"
      msg = { action: action, rack: {id: rack_id}}
    else
      msg = rack_content(rack_id, action)
    end
    user_ids = TeamRole.where(team_id: team_id).pluck(:user_id)
    User.where(root: true).or(User.where(id: user_ids)).each do |user|
      InteractiveRackViewChannel.broadcast_to(user, msg)
    end
  end

  def rack_content(rack_id, action)
   { action: action, rack: Irv::HwRackServices::Show.call(rack_id) }
  end
end
