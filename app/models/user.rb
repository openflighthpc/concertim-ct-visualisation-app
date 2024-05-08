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

class User < ApplicationRecord
  # We allow multiple valid JWTs for each user and revoke them all when the
  # user is deleted.
  include Devise::JWT::RevocationStrategies::Allowlist

  include Searchable
  default_search_scope :login, :name, :cloud_user_id

  encrypts :foreign_password
  encrypts :pending_foreign_password

  ############################
  #
  # Class Methods
  #
  ############################

  def self.perform_search(term, search_scope = default_searchable_columns, include_teams = true)
    matches = super(term, search_scope)
    return matches unless include_teams

    matching_teams = Team.perform_search(term, [:name], false)
    return matches if matching_teams.empty?

    matching_team_roles = TeamRole.where(team_id: matching_teams)
    matches.or(User.where(id: matching_team_roles.pluck(:user_id)))
  end

  ####################################
  #
  # Associations
  #
  ####################################

  has_many :team_roles,
    dependent: :destroy

  has_many :teams, through: :team_roles
  has_many :racks, through: :teams


  ###############################
  #
  # Validations
  #
  ###############################
  validates :encrypted_password, length: { maximum: 60 }
  validates :name,
    length: { maximum: 56 },
    presence: true
  validates :login,
    presence: true,
    uniqueness: true,
    length: { maximum: 80 },
    format: { with: /\A[a-zA-Z0-9\-\_\.]*\Z/, message: "can contain only alphanumeric characters, hyphens, underscores and periods."}
  validates :email,
    presence: true

  validates :cloud_user_id,
            uniqueness: true,
            length: { maximum: 255 },
            allow_nil: true,
            allow_blank: true

  ####################################
  #
  # Delegation
  #
  ####################################

  delegate :can?, :cannot?, to: :ability

  ###############################
  #
  # Devise
  #
  ###############################

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :jwt_authenticatable, jwt_revocation_strategy: self

  def ability
    return @__ability if defined?(@__ability)
    @__ability = ::Ability.new(self)
  end

  # Also store in a decryptable format, for use in the cloud environment.
  def password=(new_password)
    @password = new_password
    if @password.present?
      self.encrypted_password = password_digest(@password)
      # After a user has signed up to Concertim, the UserSignupJob will run
      # causing the middleware to create the cloud account and afterwards
      # causing the user's cloud_user_id to be set.  Once the cloud account has
      # been created, any updates to it are performed via the UserUpdateJob.
      # The UserSignupJob expects the password to be found in
      # `foreign_password` and the UserUpdateJob expects it to be in
      # `pending_foreign_password`.
      #
      # Perhaps, we should have them both look at `pending_foreign_password`
      # instead.
      if self.cloud_user_id.blank?
        self.foreign_password = @password
      else
        self.pending_foreign_password = @password
      end
    end
  end

  def active_for_authentication?
    super && deleted_at.nil?
  end

  def inactive_message
    # If the account is pending deletion, we return :invalid to be
    # indistinguishable from the account not existing.
    deleted_at.nil? ? super : :invalid
  end

  def mark_as_pending_deletion
    update(deleted_at: Time.current)
    allowlisted_jwts.destroy_all
  end

  def teams_where_admin
    @teams_where_admin ||= teams.where(team_roles: { role: 'admin' })
  end
end
