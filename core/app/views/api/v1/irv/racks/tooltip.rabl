object @rack

child :user, root: "Owner", if: current_user.root? do |rack|
  attribute name: "Name"
  attribute login: "Username"
end

node "Metadata" do |rack|
  rack.metadata
end
