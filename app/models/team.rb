class Team < ApplicationRecord

  ####################################
  #
  # Associations
  #
  ####################################

  has_many :team_roles
  has_many :users, through: :team_roles
  has_many :racks,
           class_name: 'HwRack',
           dependent: :destroy

  ############################
  #
  # Validations
  #
  ############################

  validates :name,
            presence: true,
            uniqueness: true,
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

  # TODO
  # need to move credits here too (and remove from users)
  # need to update user api to no longer have these fields
  # need to add api endpoints for teams

  validates :cost,
            numericality: { greater_than_or_equal_to: 0 },
            allow_blank: true
  validates :credits,
            numericality: { greater_than_or_equal_to: 0 },
            allow_blank: true
  validates :billing_period_end, comparison: { greater_than: :billing_period_start },
            unless: -> { billing_period_start.blank? || billing_period_end.blank? }
  validate :billing_period_start_today_or_ealier,
           if: -> { billing_period_start && billing_period_start_changed? }
  validate :billing_period_end_today_or_later,
           if: -> { billing_period_end && billing_period_end_changed? }
  validate :complete_billing_period

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
