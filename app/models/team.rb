class Team < ApplicationRecord

  ####################################
  #
  # Associations
  #
  ####################################

  has_many :user_roles
  has_many :users, through: :user_roles

  ############################
  #
  # Validations
  #
  ############################

  validates :name,
            presence: true,
            uniqueness: true,
            format: {
              with: /\A[a-zA-Z0-9\-\_]*\Z/,
              message: "can contain only alphanumeric characters, hyphens and underscores."
            }

end
