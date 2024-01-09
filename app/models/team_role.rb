class TeamRole < ApplicationRecord

  ############################
  #
  # Associations
  #
  ############################

  has_one :user
  has_one :team

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


  ############################
  #
  # Private Instance Methods
  #
  ############################

  private

  def user_not_root
    self.errors.add(:user, 'must not be super admin') if user&.root?
  end
end
