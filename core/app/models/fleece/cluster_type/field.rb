class Fleece::ClusterType::Field
  include ActiveModel::Validations

  # Format and options are driven by content defined in
  # https://docs.openstack.org/heat/latest/template_guide/hot_spec.html#parameter-groups-section

  ####################################
  #
  # Properties
  #
  ####################################

  attr_accessor :id
  attr_accessor :kind
  attr_accessor :label
  attr_accessor :description
  attr_accessor :default
  attr_accessor :hidden
  attr_accessor :constraints
  attr_accessor :immutable
  attr_accessor :tags

  ############################
  #
  # Validations
  #
  ############################

  validates :kind,
            presence: true,
            inclusion: { in: %w(string number comma_delimited_list json boolean) }

  validates :id, :label, :description,
            presence: true

  validates :hidden,
            presence: true,
            inclusion: { in: [true, false] }

  validates :immutable,
            presence: true,
            inclusion: { in: [true, false] }

  validate :default_matches_kind

  ############################
  #
  # Public Instance Methods
  #
  ############################

  def initialize(hash)
    hash = defaults.merge(hash)
    hash.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end
  end

  ############################
  #
  # Private Instance Methods
  #
  ############################

  private

  MAPPED_KIND_CLASSES = {
    "string" => [String], "number" => [Float, Integer], "comma_delimited_list" => [Array],
    "json" => [Hash], "boolean" => [TrueClass, FalseClass]
  }

  def default_matches_kind
    if default && !MAPPED_KIND_CLASSES[kind]&.include?(default.class)
      errors.add(:default, "must match value format")
    end
  end

  def defaults
    {
      hidden: false,
      immutable: false
    }
  end
end
