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

class Team < ApplicationRecord
  include Searchable
  default_search_scope :name
  scope :meets_cluster_credit_requirement, -> { where("credits >= ?", Rails.application.config.cluster_credit_requirement) }
  normalizes :project_id, with: -> project_id { project_id.strip }
  normalizes :name, with: -> name { name.strip }

  ############################
  #
  # Class Methods
  #
  ############################

  def self.perform_search(term, search_scope = default_searchable_columns, include_users=true)
    matches = super(term, search_scope)
    return matches unless include_users

    matching_users = User.perform_search(term, [:name], false)
    return matches if matching_users.empty?

    matching_team_roles = TeamRole.where(user_id: matching_users)
    matches.or(Team.where(id: matching_team_roles.pluck(:team_id)))
  end

  ####################################
  #
  # Associations
  #
  ####################################

  has_many :team_roles,
           dependent: :destroy
  has_many :users, through: :team_roles
  has_many :racks,
           class_name: 'HwRack',
           dependent: :destroy
  has_many :devices, through: :racks

  ############################
  #
  # Validations
  #
  ############################

  validates :name,
            presence: true,
            uniqueness: true,
            length: { maximum: 56 },
            format: {
              with: /\A[a-zA-Z0-9\-_\s]*\z/,
              message: "can contain only alphanumeric characters, spaces, hyphens and underscores."
            }

  validates :project_id,
            uniqueness: true,
            length: { maximum: 255 },
            allow_nil: true,
            allow_blank: true

  validates :billing_acct_id,
            uniqueness: true,
            length: { maximum: 255 },
            allow_nil: true,
            allow_blank: true

  validates :cost,
            numericality: { greater_than_or_equal_to: 0 },
            allow_blank: true
  validates :credits,
            numericality: true,
            presence: true
  validates :billing_period_end, comparison: { greater_than: :billing_period_start },
            unless: -> { billing_period_start.blank? || billing_period_end.blank? }
  validate :billing_period_start_today_or_ealier,
           if: -> { billing_period_start && billing_period_start_changed? }
  validate :billing_period_end_today_or_later,
           if: -> { billing_period_end && billing_period_end_changed? }
  validate :complete_billing_period

  ####################################
  #
  # Public Instance Methods
  #
  ####################################

  def inactive_message
    # If the account is pending deletion, we return :invalid to be
    # indistinguishable from the account not existing.
    deleted_at.nil? ? super : :invalid
  end

  def mark_as_pending_deletion
    update(deleted_at: Time.current)
  end

  ####################################
  #
  # Private Instance Methods
  #
  ####################################

  private

  def complete_billing_period
    unless !!billing_period_start == !!billing_period_end
      errors.add(:billing_period, 'must have a start date and end date, or neither')
    end
  end

  def billing_period_start_today_or_ealier
    if billing_period_start && billing_period_start > Date.current
      errors.add(:billing_period_start, 'must be today or earlier')
    end
  end

  def billing_period_end_today_or_later
    if billing_period_end && billing_period_end < Date.current
      errors.add(:billing_period_end, 'must be today or later')
    end
  end
end
