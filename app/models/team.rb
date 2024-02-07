class Team < ApplicationRecord
  include Searchable
  default_search_scope :name
  normalizes :project_id, with: -> project_id { project_id.strip }
  normalizes :name, with: -> name { name.strip }
  scope :meets_cluster_credit_requirement, -> { where("credits > ?", Rails.application.config.cluster_credit_requirement) }

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
            numericality: { greater_than_or_equal_to: 0 },
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
