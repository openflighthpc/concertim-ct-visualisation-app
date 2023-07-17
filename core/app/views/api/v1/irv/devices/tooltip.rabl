object @device
attribute description: "Description"

child :template, root: 'Template'  do
  attribute name: 'Name'
  attribute description: 'Description'
end

child :template, root: 'Resources' do
  attribute vcpus: "VCPUs"
  attribute ram: "RAM (GB)"
  attribute disk: "Disk (GB)"
end

node "Metadata", if: current_user.root? do |device|
  device.metadata
end
