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

  validates :user,
            presence: true

  validate :user_not_root


  ####################################
  #
  # Attributes
  #
  ####################################

  attr_accessor :amount, :user
  delegate :billing_acct_id, to: :user

  ############################
  #
  # Public Instance Methods
  #
  ############################

  def initialize(user:, amount: 1)
    @user = user
    @amount = amount
  end

  ######################################
  #
  # Private Instance Methods
  #
  ######################################

  private

  def user_not_root
    errors.add(:user, "cannot be an admin") if user&.root
  end
end
