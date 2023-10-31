class BroadcastRackChangeJob < ApplicationJob
  queue_as :default

  def perform(rack_id, user_id, action)
    if action == "deleted"
      msg = { action: action, rack: {id: rack_id}}
    else
      rack = HwRack.find(rack_id)
      msg = rack_content(rack, action)
    end
    User.where(root: true).or(User.where(id: user_id)).each do |user|
      InteractiveRackViewChannel.broadcast_to(user, msg)
    end
  end

  def rack_content(rack, action)
    @rack = Api::V1::RackPresenter.new(rack)
    renderer = Rabl::Renderer.new('api/v1/irv/racks/show', @rack, view_path: 'app/views', format: 'hash')
   { action: action, rack: renderer.render }
  end
end
