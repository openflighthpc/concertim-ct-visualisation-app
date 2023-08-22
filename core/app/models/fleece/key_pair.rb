class Fleece::KeyPair < ApplicationRecord
  ############################
  #
  # Validations
  #
  ############################

  validates :name,
            presence: true,
            length: { maximum: 255 }

  validates :fingerprint,
            presence: true,
            length: { maximum: 255 }

  validates :key_type,
            presence: true,
            inclusion: { in: ["ssh", "x509"], message: "%{value} is not a valid type" }

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

  attr_accessor :private_key, :public_key

  ############################
  #
  # Public Instance Methods
  #
  ############################

end
