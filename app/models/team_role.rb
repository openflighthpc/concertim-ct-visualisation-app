class TeamRole < ApplicationRecord

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
            inclusion: { in: %w(admin member), message: "%{value} is not a valid role" }

  validates :user_id, uniqueness: { scope: :team_id, message: "User can only have one role per team" }

  validate :user_not_root

  ######################################
  #
  # Hooks
  #
  ######################################

  after_commit :broadcast_change

  ############################
  #
  # Private Instance Methods
  #
  ############################

  private

  def user_not_root
    self.errors.add(:user, 'must not be super admin') if user&.root?
  end

  # What user can see in irv may have changed
  def broadcast_change
    BroadcastUserRacksJob.perform_now(self.user_id)
  end
end
