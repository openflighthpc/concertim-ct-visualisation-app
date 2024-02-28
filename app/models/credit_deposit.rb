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
