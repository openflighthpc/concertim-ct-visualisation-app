object @teams
node do |team|
  partial('api/v1/teams/show', object: team)
end
