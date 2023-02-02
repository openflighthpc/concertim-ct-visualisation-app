object @group
attributes :id, :name
attribute type: :groupType
attribute breach_group: :breachGroup
node :memberIds do |g|
  {
    :sensorIds => g.group_sensors.map(&:id),
    :deviceIds => g.group_devices.map(&:id), 
    :chassisIds => g.group_chassis.map(&:id),
  } 
end
