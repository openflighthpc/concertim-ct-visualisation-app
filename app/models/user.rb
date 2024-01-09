class User < ApplicationRecord
  # We allow multiple valid JWTs for each user and revoke them all when the
  # user is deleted.
  include Devise::JWT::RevocationStrategies::Allowlist

  include Searchable
  default_search_scope :login, :name, :cloud_user_id

  encrypts :foreign_password
  encrypts :pending_foreign_password

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

  ####################################
  #
  # Private Instance Methods
  #
  ####################################

  private

  def strip_project_id
    self.project_id = nil if self.project_id.blank?
  end

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
