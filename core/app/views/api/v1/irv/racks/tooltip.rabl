object @rack

child :user, root: "Owner", if: current_user.root? do |rack|
  attribute name: "Name"
  attribute login: "Username"
end

node "Metadata" do |rack|
  rack.metadata
end

node("Network Details", :unless => lambda { |r| r.network_details.blank? }) do |rack|
  rack.network_details
end

node("Creation Output", :unless => lambda { |r| r.creation_output.blank? }) do |rack|
  { result: rack.creation_output }
end
