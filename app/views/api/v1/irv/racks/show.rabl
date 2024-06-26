object @rack
attributes :id, :name
attribute :currency_cost => :cost
attributes u_height: :uHeight, status: :buildStatus
node(:teamRole) do |rack|
  if locals[:user].root
    "superAdmin"
  else
    locals[:user].team_roles.where(team_id: rack.team_id).pluck(:role).first
  end
end

child :team, root: 'owner' do
  extends 'api/v1/teams/show'
end

node(:template) do |rack|
  partial('api/v1/irv/racks/template', object: rack.template)
end

child(:chassis, root: 'Chassis') do |foo|
  attribute :id, :name
  node(:type) { "RackChassis" }
  attribute :facing
  node(:rows) { 1 }
  node(:slots) { 1 }
  node(:cols) { 1 }
  attribute :rack_start_u => :uStart
  attribute :rack_end_u => :uEnd

  node(:template) do |chassis|
    partial('api/v1/irv/racks/template', object: chassis.template)
  end

  node(:Slots) do |chassis|
    {
      id: chassis.device.id,
      col: 1,
      row: 1,
      Machine: {
        id: chassis.device.id,
        name: chassis.device.name,
        buildStatus: chassis.device.status,
        cost: chassis.device.currency_cost,
        type: chassis.device.type
      },
    }
  end
end
