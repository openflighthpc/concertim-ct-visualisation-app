module Uma
  class User < ApplicationRecord

    self.table_name = "users"

    ####################################
    #
    # Associations
    #
    ####################################

    has_many :racks,
      class_name: 'Ivy::HwRack',
      dependent: :destroy


    ####################################
    #
    # Hooks
    #
    ####################################
    before_validation :strip_project_id


    ###############################
    #
    # Validations
    #
    ###############################
    validates :encrypted_password, length: { maximum: 60 }
    validates :name, :email, :login, presence: true
    validates :login,
      uniqueness: true,
      format: { with: /\A[a-zA-Z0-9\-\_\.]*\Z/, message: "can contain only alphanumeric characters, hyphens, underscores and periods."}
    validates :project_id,
      uniqueness: true,
      length: { maximum: 255 },
      allow_nil: true,
      allow_blank: true
    validates :cloud_user_id,
      uniqueness: true,
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
      :jwt_authenticatable, jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

    def ability
      return @__ability if defined?(@__ability)
      @__ability = ::Ability.new(self)
    end

    # Also store password in plaintext, for use in the cloud environment. In future this MUST be
    # encrypted.
    def password=(new_password)
      @password = new_password
      if @password.present?
        self.encrypted_password = password_digest(@password)
        self.fixme_encrypt_this_already_plaintext_password = @password
      end
    end


    ####################################
    #
    # Private Instance Methods
    #
    ####################################

    def strip_project_id
      self.project_id = nil if self.project_id.blank?
    end
  end
end
