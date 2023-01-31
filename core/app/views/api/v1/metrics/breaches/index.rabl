object false
node :devices do
  @devices.map(&:id)
end
node :sensors do
  @sensors.map(&:id)
end
node :chassis do
  @chassis.map(&:id)
end
node :racks do
  @racks.map(&:id)
end
