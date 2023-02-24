object @rack
attributes :id, :name, :u_height

child :devices, root: 'devices', object_root: false, if: @include_occupation_details do
  extends 'api/v1/devices/devices/show'
end
