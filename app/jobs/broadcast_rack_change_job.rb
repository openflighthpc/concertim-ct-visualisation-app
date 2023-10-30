class BroadcastRackChangeJob < ApplicationJob
  queue_as :default

  def perform(rack_id)
    rack = HwRack.find(rack_id)
    msg = content(rack)
    User.where(root: true).or(User.where(id: rack.user_id)).each do |user|
      InteractiveRackViewChannel.broadcast_to(user, msg)
    end
  end

  def content(rack)
    @rack = Api::V1::RackPresenter.new(rack)
    renderer = Rabl::Renderer.new('api/v1/irv/racks/show', @rack, view_path: 'app/views', format: 'hash')
   { Racks: { Rack: [renderer.render] }}
  end
end
