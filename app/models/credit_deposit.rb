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
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

class CreditDeposit
  include ActiveModel::API

  ############################
  #
  # Validations
  #
  ############################

  validates :amount,
            presence: true,
            numericality: { greater_than: 0 }

  validates :team,
            presence: true

  validate :team_has_project_id
  validate :team_has_billing_account

  ####################################
  #
  # Attributes
  #
  ####################################

  attr_accessor :amount, :team
  delegate :billing_acct_id, to: :team

  ############################
  #
  # Public Instance Methods
  #
  ############################

  def initialize(team:, amount: 1)
    @team = team
    @amount = amount
  end

  ############################
  #
  # Private Instance Methods
  #
  ############################

  private

  def team_has_project_id
    errors.add(:team, "must have a project id") if team && !team.project_id
  end

  def team_has_billing_account
    errors.add(:team, "must have a billing account id") if team && !team.billing_acct_id
  end

end
