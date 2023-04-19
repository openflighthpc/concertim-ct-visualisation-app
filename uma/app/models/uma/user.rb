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

    ###############################
    #
    # Validations
    #
    ###############################
    validates :encrypted_password, length: { maximum: 60 }
    validates :firstname, :surname, :email, :login, presence: true
    validates :login,
      uniqueness: true,
      format: { with: /\A[a-zA-Z0-9\-\_\.]*\Z/, message: "can contain only alphanumeric characters, hyphens, underscores and periods."}

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
  end
end
