class Invoice
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :account
  attribute :amount, :decimal, default: 0
  attribute :balance, :decimal, default: 0
  attribute :credit_adj, :decimal, default: 0
  attribute :currency, :string
  attribute :invoice_date, :date
  attribute :invoice_id, :string
  attribute :invoice_number, :string
  attribute :items, default: ->() { [] }
  attribute :refund_adj, :decimal, default: 0
  attribute :status, :string, default: "DRAFT"

  def draft?
    status == "DRAFT" || invoice_number.nil?
  end

  def to_key
    [invoice_id]
  end

  def persisted?
    !draft?
  end

  # Extract these `formatted_*` methods to a presenter if they get
  # large/complicated/numerous.

  def formatted_invoice_date
    invoice_date.to_formatted_s(:rfc822)
  end

  def formatted_amount_charged
    "#{"%0.2f" % amount} #{currency}"
  end

  def formatted_amount_paid
    "#{"%0.2f" % amount_paid} #{currency}"
  end

  def formatted_balance
    "#{"%0.2f" % balance} #{currency}"
  end

  def formatted_credit_adjustment
    "#{"%0.2f" % credit_adj} #{currency}"
  end

  def formatted_refund_adjustment
    "#{"%0.2f" % refund_adj} #{currency}"
  end

  private

  def amount_paid
    amount + credit_adj - refund_adj - balance
  end
end
