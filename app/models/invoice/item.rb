class Invoice::Item
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :amount, :decimal, default: 0
  attribute :currency, :string
  attribute :end_date, :date
  attribute :invoice
  attribute :openstack_stack_id, :string
  attribute :openstack_stack_name, :string
  attribute :start_date, :date

  validates :amount, presence: true, numericality: true
  validates :currency, presence: true
  validates :end_date, presence: true
  validates :invoice, presence: true
  validates :openstack_stack_id, presence: true
  validates :openstack_stack_name, presence: true
  validates :start_date, presence: true

  def rack
    HwRack.find_by_openstack_id(openstack_stack_id)
  end

  # Extract these `formatted_*` and `pretty_*` methods to a presenter if they
  # get large/complicated/numerous.

  def formatted_date
    if end_date.nil?
      formatted_start_date
    else
      "#{formatted_start_date} - #{formatted_end_date}"
    end
  end

  def formatted_amount
    "#{"%0.2f" % amount} #{currency}"
  end

  def formatted_start_date
    start_date.to_formatted_s(:rfc822)
  end

  def formatted_end_date
    end_date.to_formatted_s(:rfc822)
  end
end
