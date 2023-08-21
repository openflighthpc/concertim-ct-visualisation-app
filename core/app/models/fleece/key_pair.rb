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
            inclusion: { in: ["ssh_key", "x509"], message: "%{value} is not a valid type" }

  ####################################
  #
  # Associations
  #
  ####################################

  belongs_to :user, class_name: "Uma::User"

  ####################################
  #
  # Attributes
  #
  ####################################

  attr_accessor :private_key

  ############################
  #
  # Public Instance Methods
  #
  ############################

end
