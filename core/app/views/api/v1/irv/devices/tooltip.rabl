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

attribute "Login" do |device|
  attribute public_ips: "Public IPs"
  attribute private_ips: "Private IPs"
  attribute ssh_key: "SSH Key"
  attribute login_user: "Login username"
end

node("Volume Details", :unless => lambda { |d| d.volume_details.blank? }) do |device|
  device.volume_details
end

node "Metadata" do |device|
  device.metadata
end
