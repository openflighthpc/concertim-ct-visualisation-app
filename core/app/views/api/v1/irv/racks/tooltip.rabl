object @rack
attribute manufacturer: "Manufacturer"
attribute model: "Model"
attribute description: "Description"
attribute serial_number: "Serial number"
attribute asset_number: "Asset number"
attribute number_of_devices: "Number of devices"
node :"Free space" do |rack|
  "#{rack.total_space - rack.space_used}U"
end
node :"Used space" do |rack|
  "#{rack.space_used}U"
end
