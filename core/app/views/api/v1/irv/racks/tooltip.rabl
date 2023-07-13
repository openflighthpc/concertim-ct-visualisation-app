object @rack
attribute status: "Status"

child :user, root: "Owner", if: current_user.root? do |rack|
  attribute name: "Name"
  attribute login: "Username"
end

node "Metadata", if: current_user.root? do |rack|
  rack.metadata
end
