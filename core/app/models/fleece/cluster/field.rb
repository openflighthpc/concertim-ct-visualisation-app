class Fleece::Cluster::Field
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
  attr_accessor :value

  ############################
  #
  # Validations
  #
  ############################

  validates :type,
            presence: true,
            inclusion: { in: %w(string number comma_delimited_list json boolean) }

  validates :id, :label, :value,
            presence: true

  validates :hidden,
            inclusion: { in: [true, false] }

  validates :immutable,
            inclusion: { in: [true, false] }

  validate :valid_number?, if: -> { type == "number" }
  validate :valid_json?, if: -> { type == "json" }
  validate :valid_boolean?, if: -> { type == "boolean" }
  validate :validate_modulo, if: -> { constraints["modulo"] }
  validate :validate_range, if: -> { constraints["range"] }
  validate :validate_length, if: -> { constraints["length"] }
  validate :validate_pattern, if: -> { constraints["allowed_pattern"] }
  validate :validate_allowed_value, if: -> { constraints["allowed_values"] }

  ############################
  #
  # Public Instance Methods
  #
  ############################

  def initialize(id, details)
    @id = id
    details = default_details.merge(details)
    details.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end
    self.default ||= step[:min]
    self.label ||= id
    self.value = default
  end

  # Puts into a more usable format. This could be done at cluster type creation instead of here.
  def constraints=(values)
    @constraints = {}
    values.each do |constraint|
      constraint_name = constraint.keys.find {|key| key != "description" }
      @constraints[constraint_name] = {
        details: constraint[constraint_name],
        description: constraint["description"]
      }
    end
  end

  def constraint_names
    @constraint_names ||= constraints.keys
  end

  def allowed_values?
    allowed_values.any?
  end

  def allowed_values
    @_allowed_values ||= get_constraint_details("allowed_values")
  end

  # take these out of the model. Cell? Presenter?

  def form_field_type
    return 'hidden_field' if hidden

    allowed_values? ? 'select' : "#{MAPPED_FIELD_TYPES[type]}"
  end

  def select_box?
    form_field_type == 'select'
  end

  def form_options
    options = {
      required: form_field_type != 'check_box',
      disabled: immutable,
      class: 'new-cluster-field',
      name: "fleece_cluster[cluster_params][#{id}]",
      id: "fleece_cluster_cluster_params_#{id}"
    }
    unless allowed_values?
      options[:placeholder] = form_placeholder
      options = options.merge(min_max).merge(required_length).merge(step).merge(allowed_pattern)
    end
    options
  end

  def min_max
    return {} unless type == "number"

    get_constraint_details("range")
  end

  def required_length
    return {} unless %w[string json comma_delimited_list].include?(type)

    required = get_constraint_details("length")
    required.keys.each do |key|
      required["#{key}length".to_sym] = required.delete(key)
    end

    required
  end

  def step
    return {} unless type == "number"

    details = get_constraint_details("modulo")
    return {} if details.empty?

    details[:min] = details["offset"] if details["offset"]
    details
  end

  def allowed_pattern
    return {} unless type == "string"

    pattern = get_constraint_details("allowed_pattern")
    return {} if pattern.empty?

    { pattern: pattern }
  end

  # possible future improvement: have JS for creating text boxes for each array/ hash option instead of
  # expecting user to input text in correct format
  def form_placeholder
    case type
    when 'comma_delimited_list'
      'A list of choices separated by commas: choice1,choice2,choice3'
    when 'json'
      'Collection of keys and values: {"key1":"value1", "key2":"value2"}'
    end
  end

  def constraint_text
    constraint_names.map {|name| constraints[name][:description] }.join(". ")
  end

  ############################
  #
  # Private Instance Methods
  #
  ############################

  private

  MAPPED_FIELD_TYPES = {
    "string" => "text_field", "number" => "number_field", "comma_delimited_list" => "text_area",
    "json" => "text_area", "boolean" => "check_box"
  }

  def default_details
    {
      hidden: false,
      immutable: false,
      constraints: {},
    }
  end

  def get_constraint_details(name)
    target_hash = constraints[name]
    target_hash ? target_hash[:details] : {}
  end

  def valid_number?
    unless type == "number" && ([Float, Integer].include?(value.class) || /^-?\d*\.?\d+$/.match?(value))
      errors.add(:value, "must be a valid number")
    end
  end

  def valid_json?
    return unless type == "json"

    begin
      JSON.parse(value)
    rescue
      errors.add(:value, "must be valid JSON")
    end
  end

  def valid_boolean?
    unless type == "boolean" && ["f", "false", false, "0", 0, "off", "t", "true", true, "1", 1, "on"].include?(value)
      errors.add(:value, "must be a valid boolean")
    end
  end

  def validate_modulo
    return unless type == "number"

    constraint = constraints["modulo"]
    number = value.to_f
    offset = constraint[:details]["offset"]
    step = constraint[:details]["step"]
    unless (offset && number == offset) || (offset ? number - offset : number) % step == 0
      error_message = constraint[:description] || "must match step of #{step}#{" and offset of #{offset}" if offset}"
      errors.add(:value, error_message)
    end
  end

  def validate_range
    return unless type == "number"

    constraint = constraints["range"]
    number = value.to_f
    min = constraint[:details]["min"] || number # may have only min, only max, or both
    max = constraint[:details]["max"] || number
    unless number >= min && number <= max
      error_message = constraint[:description] || "must be between #{min} and #{max} (inclusive)"
      errors.add(:value, error_message)
    end
  end

  def validate_length
    return unless %w(string comma_delimited_list json).include?(type)

    constraint = constraints["length"]
    length = value.length
    min = constraint[:details]["min"] || length
    max = constraint[:details]["max"] || length
    unless length >= min && length <= max
      error_message = constraint[:description] || "must be between #{min} and #{max} characters (inclusive)"
      errors.add(:value, error_message)
    end
  end

  def validate_pattern
    return unless type == "string"

    constraint = constraints["allowed_pattern"]
    pattern = constraint[:details]
    unless Regexp.new(pattern).match?(value)
      error_message = constraint[:description] || "must match pattern #{pattern}"
      errors.add(:value, error_message)
    end
  end

  def validate_allowed_value
    unless !allowed_values? || allowed_values.include?(value)
      error_message = constraint[:description] || "must be chosen from one of the drop down options"
      errors.add(:value, error_message)
    end
  end

  # if immutable, must have a default value
  # if hidden, must have a default value
end
