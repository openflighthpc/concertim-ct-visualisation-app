class Fleece::KeyPair < ApplicationRecord
  ############################
  #
  # Validations
  #
  ############################

  validates :name,
            presence: true,
            length: { maximum: 255 }

  validates :key_type,
            presence: true,
            inclusion: { in: ["SSH Key", "X509 Certificate"], message: "%{value} is not a valid type" }

  validates :private_key,
            presence: true

  ####################################
  #
  # Associations
  #
  ####################################

  belongs_to :user, class_name: "Uma::User"

  ############################
  #
  # Public Instance Methods
  #
  ############################

end
