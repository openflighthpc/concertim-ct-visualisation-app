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
  attr_accessor :order
  attr_accessor :type
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

  validates :type,
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

  validate :default_matches_type

  ############################
  #
  # Public Instance Methods
  #
  ############################

  def initialize(id, hash)
    @id = id
    hash = defaults.merge(hash)
    hash.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end
  end

  def allowed_values?
    allowed_values.any?
  end

  def allowed_values
    return @_allowed_values if defined?(@_allowed_values)

    target_hash = constraints.find {|constraint| constraint.keys.include?("allowed_values") }
    @_allowed_values = target_hash ? target_hash["allowed_values"] : {}
  end

  # take these out of the model. Cell? Presenter?

  def form_field_type
    allowed_values? ? 'select' : "#{MAPPED_FIELD_TYPES[type]}"
  end

  def form_options
    allowed_values? ? allowed_values : {required: true}
  end

  ############################
  #
  # Private Instance Methods
  #
  ############################

  private

  MAPPED_TYPE_CLASSES = {
    "string" => [String], "number" => [Float, Integer], "comma_delimited_list" => [Array],
    "json" => [Hash], "boolean" => [TrueClass, FalseClass]
  }

  MAPPED_FIELD_TYPES = {
    "string" => "text_field", "number" => "number_field", "comma_delimited_list" => "text_field",
    "json" => "text_field", "boolean" => "check_box"
  }

  def default_matches_kind
    if default && !MAPPED_TYPE_CLASSES[type]&.include?(default.class)
      errors.add(:default, "must match value format")
    end
  end

  def defaults
    {
      hidden: false,
      immutable: false,
      constraints: {}
    }
  end
end
