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
end
