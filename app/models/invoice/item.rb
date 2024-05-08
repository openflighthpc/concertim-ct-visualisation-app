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

class Invoice::Item
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :amount, :decimal, default: 0
  attribute :currency, :string
  attribute :end_date, :date
  attribute :invoice
  attribute :start_date, :date
  attribute :type, :string

  validates :amount, presence: true, numericality: true
  validates :currency, presence: true
  validates :end_date, presence: true
  validates :invoice, presence: true
  validates :start_date, presence: true
  validates :type, presence: true

  # Extract these `formatted_*` and `pretty_*` methods to a presenter if they
  # get large/complicated/numerous.

  def formatted_date
    "#{formatted_start_date} - #{formatted_end_date}"
  end

  def description
    ""
  end

  def cost
    "-"
  end

  def credits
    "-"
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
