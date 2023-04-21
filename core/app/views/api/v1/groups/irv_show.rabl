object @group
attributes :id, :name
attribute type: :groupType
node :memberIds do |g|
  {
    :deviceIds => g.group_devices.map(&:id), 
    :chassisIds => g.group_chassis.map(&:id),
  } 
end
