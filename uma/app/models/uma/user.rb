module Uma
  class User < ApplicationRecord

    self.table_name = "users"

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

    def can?(action, resource)
      # XXX Is this OK?  Do we want Emma::CanCanAbilityManager back.
      Ability.new(self).can?(action, resource)
    end
  end
end
