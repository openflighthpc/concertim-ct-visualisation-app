class TeamRole < ApplicationRecord
  include Searchable
  default_search_scope :role

  ############################
  #
  # Class Methods
  #
  ############################

  def self.perform_search(term, search_scope = default_searchable_columns)
    matches = super
    matching_users = User.perform_search(term, [:name], false)
    return matches if matching_users.empty?

    matches.or(TeamRole.where(user_id: matching_users.pluck(:id)))
  end

  ############################
  #
  # Constants
  #
  ############################

  VALID_ROLES = %w(admin member)

  ############################
  #
  # Associations
  #
  ############################

  belongs_to :user
  belongs_to :team

  ############################
  #
  # Validations
  #
  ############################

  validates :role,
            presence: true,
            inclusion: { in: VALID_ROLES, message: "%{value} is not a valid role" }

  validates :user_id, uniqueness: { scope: :team_id, message: "User can only have one role per team" }

  validate :user_not_root
  validate :one_role_for_single_user_team

  ######################################
  #
  # Hooks
  #
  ######################################

  after_commit :broadcast_change

  ############################
  #
  # Public Instance Methods
  #
  ############################

  def user_name
    self.user.name
  end

  ############################
  #
  # Private Instance Methods
  #
  ############################

  private

  def user_not_root
    self.errors.add(:user, 'must not be super admin') if user&.root?
  end

  def one_role_for_single_user_team
    if team&.single_user && team.team_roles.where.not(id: id).exists?
      self.errors.add(:team, 'is a single user team and already has an assigned user')
    end
  end

  # What user can see in irv may have changed
  def broadcast_change
    BroadcastUserRacksJob.perform_now(self.user_id)
  end
end
