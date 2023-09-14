class KeyPair
  include ActiveModel::API

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

  validates :user,
            presence: true

  ####################################
  #
  # Attributes
  #
  ####################################

  attr_accessor :name, :fingerprint, :key_type, :private_key, :public_key, :user

  ############################
  #
  # Public Instance Methods
  #
  ############################

  def initialize(user:, name: nil, fingerprint: nil, key_type: "ssh", public_key: nil, private_key: nil)
    @user = user
    @name = name
    @fingerprint = fingerprint
    @key_type = key_type
    @public_key = public_key
    @private_key = private_key
  end
end
