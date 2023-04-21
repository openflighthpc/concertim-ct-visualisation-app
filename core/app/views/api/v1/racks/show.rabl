object @rack
attributes :id, :name, :u_height

child :user, root: 'owner', if: current_user.root? do
  attributes :login, :name
end

child :devices, root: 'devices', object_root: false, if: @include_occupation_details do
  extends 'api/v1/devices/show'
end
