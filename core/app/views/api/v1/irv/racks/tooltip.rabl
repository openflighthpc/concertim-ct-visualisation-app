object @rack
node "Owner", if: current_user.root? do |rack|
  rack.user.name
end
