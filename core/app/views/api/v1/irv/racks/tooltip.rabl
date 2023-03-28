object @rack
attribute description: "Description"
attribute number_of_devices: "Number of devices"
node :"Free space" do |rack|
  "#{rack.total_space - rack.space_used}U"
end
node :"Used space" do |rack|
  "#{rack.space_used}U"
end
