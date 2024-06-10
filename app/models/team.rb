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
  has_many :compute_unit_deposits,
           dependent: :destroy

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

  def compute_unit_allocation
    racks.reduce(0) { |sum, rack| sum + rack.compute_unit_allocation }
  end

  def remaining_compute_units
    @remaining_compute_units ||= compute_unit_deposits.active.sum(:amount) - compute_unit_allocation
  end

  def hourly_compute_units
    racks.reduce(0) { |sum, rack| sum + rack.hourly_compute_units }
  end

  def meets_cluster_compute_unit_requirement?
    remaining_compute_units >= Rails.application.config.cluster_compute_unit_requirement
  end
end
