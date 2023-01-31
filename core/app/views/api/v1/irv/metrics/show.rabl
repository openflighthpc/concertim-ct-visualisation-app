object @metric
attribute :name
child :values do
  node :devices do
    @devices.map { |d| {:id => d.id, :value => d.value } }
  end
  node :chassis do
    @chassis.map { |c| {:id => c.id, :value => c.value } }
  end
end
