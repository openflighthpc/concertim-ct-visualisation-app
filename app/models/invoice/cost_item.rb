class Invoice::CostItem < Invoice::Item
  attribute :openstack_stack_id, :string
  attribute :openstack_stack_name, :string

  validates :openstack_stack_id, :openstack_stack_name, presence: true

  def rack
    HwRack.find_by_openstack_id(openstack_stack_id)
  end

  def description
    "Rack costs: #{openstack_stack_name}"
  end

  def cost
    formatted_amount
  end
end
