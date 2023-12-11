class Invoice::Item
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :amount, :decimal, default: 0
  attribute :currency, :string
  attribute :description, :string
  attribute :end_date, :date
  attribute :item_type, :string
  attribute :plan_name, :string
  attribute :start_date, :date

  # Extract these `formatted_*` and `pretty_*` methods to a presenter if they
  # get large/complicated/numerous.

  # We don't display credit adjustments or refunds.
  HIDDEN_TYPES = %w(REFUND CHARGED_BACK CBA_ADJ).freeze
  def display?
    !HIDDEN_TYPES.include?(item_type)
  end

  def pretty_plan_name
    plan_name
  end

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
