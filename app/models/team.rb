class Team < ApplicationRecord

  ####################################
  #
  # Associations
  #
  ####################################

  has_many :user_roles
  has_many :users, through: :user_roles
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

end
