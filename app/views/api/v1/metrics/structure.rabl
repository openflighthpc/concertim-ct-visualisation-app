collection @definitions
attributes :id, :name, :units, :min, :max
node :format do |metric|
  metric.units != '' ? "%s #{metric.units}" : "%s"
end
