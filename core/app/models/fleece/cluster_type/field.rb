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
    @_allowed_values ||= find_constraint("allowed_values")
  end

  # take these out of the model. Cell? Presenter?

  def form_field_type
    allowed_values? ? 'select' : "#{MAPPED_FIELD_TYPES[type]}"
  end

  def form_options
    return allowed_values if allowed_values?

    {
       required: true,
       placeholder: form_placeholder
     }.merge(min_max).merge(required_length).merge(step).merge(allowed_pattern)
  end

  def min_max
    return {} unless type == "number"

    find_constraint("range")
  end

  def required_length
    return {} unless %w[string json comma_delimited_list].include?(type)

    required = find_constraint("length")
    required.keys.each do |key|
      required["#{key}length"] = required.delete(key)
    end

    required
  end

  def step
    return {} unless type == "number"

    details = find_constraint("modulo")
    return {} if details.empty?

    details["min"] = details.delete("step") if details["step"]
    details
  end

  def allowed_pattern
    return {} unless type == "string"

    pattern = find_constraint("allowed_pattern")
    return {} if pattern.empty?

    {pattern: pattern}
  end

  # possible future improvement: have JS for creating text boxes for each array/ hash option instead of
  # expecting user to input text in correct format
  def form_placeholder
    case type
    when 'comma_delimited_list'
      'A list of choices separated by commas: choice1,choice2,choice3'
    when 'json'
      'Collection of keys and values: {"key1": "value1", "key2": "value2"}'
    end
  end

  ############################
  #
  # Private Instance Methods
  #
  ############################

  private

  MAPPED_TYPE_CLASSES = {
    "string" => [String], "number" => [Float, Integer], "comma_delimited_list" => [String],
    "json" => [String], "boolean" => [TrueClass, FalseClass]
  }

  MAPPED_FIELD_TYPES = {
    "string" => "text_field", "number" => "number_field", "comma_delimited_list" => "text_area",
    "json" => "text_area", "boolean" => "check_box"
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

  def find_constraint(name)
    target_hash = constraints.find {|constraint| constraint.keys.include?(name) }
    target_hash ? target_hash[name] : {}
  end
end
