#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

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

  validates :account, presence: true
  validates :amount, presence: true, numericality: true
  validates :balance, presence: true, numericality: true
  validates :credit_adj, presence: true, numericality: true
  validates :currency, presence: true
  validates :invoice_date, presence: true
  validates :invoice_id, presence: true
  validate do
    errors.add(:items, message: "is not an array") unless items.is_a?(Array)
  end
  validates :refund_adj, presence: true, numericality: true
  validates :status, presence: true

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
    "#{'+' if credit_adj > 0}#{"%0.2f" % credit_adj} #{currency}"
  end

  def formatted_refund_adjustment
    "#{"%0.2f" % refund_adj} #{currency}"
  end

  def sorted_items
    self.items.sort_by(&:type)
  end

  private

  def amount_paid
    amount + credit_adj - refund_adj - balance
  end
end
