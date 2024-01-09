object @rack
attributes :id, :name, :u_height, :metadata, :status, :cost, :network_details, :creation_output, :order_id, :modified_timestamp

child :team, root: 'owner' do
  extends 'api/v1/teams/show'
end

child :devices, root: 'devices', object_root: false, if: @include_occupation_details do
  extends 'api/v1/devices/show'
end
