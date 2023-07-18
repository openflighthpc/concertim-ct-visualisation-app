object @rack
attributes :id, :name, :u_height, :metadata, :status

child :user, root: 'owner', if: current_user.root? do
  extends 'api/v1/users/show'
end

child :devices, root: 'devices', object_root: false, if: @include_occupation_details do
  extends 'api/v1/devices/show'
end
