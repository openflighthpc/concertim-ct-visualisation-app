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

node("Login", :if => lambda { |d| d.has_login_details? }) do |device|
  {
    "Public IPs" => device.public_ips,
    "Private IPs" => device.private_ips,
    "SSH Key" => device.ssh_key,
    "Login username" => device.login_user
  }
end

node("Volume Details", :unless => lambda { |d| d.volume_details.blank? }) do |device|
  device.volume_details
end

node "Metadata" do |device|
  device.metadata
end
