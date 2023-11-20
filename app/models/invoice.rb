class Invoice
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :account
  attribute :amount, :decimal, default: 0
  attribute :balance, :decimal, default: 0
  attribute :currency, :string
  attribute :draft, :boolean, default: true
  attribute :invoice_date, :date
  attribute :invoice_id, :string
  attribute :invoice_number, :string
  attribute :items, default: ->() { [] }
  attribute :amount_paid, :decimal, default: 0

  def draft?
    !!draft
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
end
