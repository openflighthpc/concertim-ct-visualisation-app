class BroadcastRackChangeJob < ApplicationJob
  queue_as :default

  def perform(rack_id, team_id, action)
    if action == "deleted"
      msg = { action: action, rack: {id: rack_id}}
    else
      msg = rack_content(rack_id, action)
    end
    user_roles = TeamRole.where(team_id: team_id)
    role_mapping = user_roles.pluck(:user_id, :role).to_h
    User.where(root: true).or(User.where(id: role_mapping.keys)).each do |user|
      role = user.root? ? "superAdmin" : role_mapping[user.id]
      msg[:rack][:teamRole] = role
      InteractiveRackViewChannel.broadcast_to(user, msg)
    end
  end

  def rack_content(rack_id, action)
    { action: action, rack: Irv::HwRackServices::Show.call(rack_id) }
  end
end
