object @metric
attribute :name
child :values do
  node :devices do
    @devices.map { |d| {:id => d.id, :value => d.value } }
  end
  # Deprecated chassis.  Remove when the IRV is updated to not expect it.
  node :chassis do
    []
  end
end
