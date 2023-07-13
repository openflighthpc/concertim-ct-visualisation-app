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
  attr_accessor :immutable
  attr_accessor :value
  attr_reader :constraints

  ############################
  #
  # Validations
  #
  ############################

  validates :type,
            presence: true,
            inclusion: { in: %w(string number comma_delimited_list json boolean) }

  validates :id, :label, :value, :order,
            presence: true

  validate :valid_number?, if: -> { value && type == "number" }
  validate :valid_json?, if: -> { value && type == "json" }
  validate :valid_boolean?, if: -> { value && type == "boolean" }
  validate :validate_constraint_formats
  validate :validate_modulo, if: -> { value && constraints["modulo"] && !errors[:modulo] }
  validate :validate_range, if: -> { value && constraints["range"] && !errors[:range] }
  validate :validate_length, if: -> { value && constraints["length"] && !errors[:length] }
  validate :validate_pattern, if: -> { value && constraints["allowed_pattern"] && !errors[:allowed_pattern] }
  validate :validate_allowed_value, if: -> { value && constraints["allowed_values"] && !errors[:allowed_values] }

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
    self.label ||= id.gsub("_", " ").capitalize
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

  def step
    return {} unless type == "number"

    details = get_constraint_details("modulo")
    return {} if details.empty?

    details[:min] = details["offset"] if details["offset"]
    details
  end

  def get_constraint_details(name)
    target_hash = constraints[name]
    target_hash ? target_hash[:details].clone : {}
  end

  private

  ############################
  #
  # Private Instance Methods
  #
  ############################

  def default_details
    {
      hidden: false,
      immutable: false,
      constraints: {},
    }
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
    min = constraint[:details]["min"]
    max = constraint[:details]["max"]
    unless (!min || number >= min) && (!max || number <= max)
      error_message = constraint[:description]
      if error_message.blank?
        error_message = "must be "
        error_message << "at least #{min}" if min
        error_message << "#{ " and " if min}at most #{max}" if max
      end
      errors.add(:value, error_message)
    end
  end

  def validate_length
    return unless %w(string comma_delimited_list json).include?(type)

    constraint = constraints["length"]
    length = value.length
    min = constraint[:details]["min"]
    max = constraint[:details]["max"]
    unless (!min || length >= min) && (!max || length <= max)
      error_message = constraint[:description]
      if error_message.blank?
        error_message = "must be "
        error_message << "at least #{min} characters" if min
        error_message << "#{ " and " if min}at most #{max} characters" if max
      end
      errors.add(:value, error_message)
    end
  end

  def validate_pattern
    return unless type == "string"

    constraint = constraints["allowed_pattern"]
    pattern = constraint[:details]
    reg = Regexp.new(pattern)
    unless reg.match?(value) && !reg.match(value).to_s.blank?
      error_message = constraint[:description] || "must match pattern #{pattern}"
      errors.add(:value, error_message)
    end
  end

  def validate_allowed_value
    unless !allowed_values? || allowed_values.include?(value) || (type == "number" && allowed_values.include?(value.to_f))
      error_message = constraints["allowed_values"][:description] || "must be chosen from one of the drop down options"
      errors.add(:value, error_message)
    end
  end

  def validate_constraint_formats
    constraint_names.each do |constraint_name|
      self.send("validate_#{constraint_name}_constraint")
    end
  end

  def validate_modulo_constraint
    constraint = constraints["modulo"]
    step = constraint[:details]["step"]
    if step.nil?
      errors.add(:modulo, 'constraint must contain step details')
    elsif ![Integer, Float].include?(step.class)
      errors.add(:modulo, 'constraint step must be a valid number')
    end
    offset = constraint[:details]["offset"]
    if offset && ![Integer, Float].include?(offset.class)
      errors.add(:modulo, 'constraint offset must be empty or a valid number')
    end
  end

  def validate_range_constraint
    constraint = constraints["range"]
    blank = true
    constraint[:details].each do |key, value|
      unless [Integer, Float].include?(value.class)
        errors.add(:range, "constraint #{key} must be a valid number")
      end
      blank = false unless value.nil?
    end
    errors.add(:range, "constraint must have a max and/or min") if blank
  end

  def validate_length_constraint
    constraint = constraints["length"]
    blank = true
    constraint[:details].each do |key, value|
      unless [Integer, Float].include?(value.class)
        errors.add(:length, "constraint #{key} must be a valid number")
      end
      blank = false unless value.nil?
    end
    errors.add(:length, "constraint must have a max and/or min") if blank
  end

  def validate_allowed_pattern_constraint
    begin
      Regexp.new(constraints["allowed_pattern"][:details])
    rescue
      errors.add(:allowed_pattern, 'invalid regex')
    end
  end

  def validate_allowed_values_constraint
    constraint = constraints["allowed_values"][:details]
    if !constraint.is_a?(Array)
      errors.add(:allowed_values, 'must be an array of values')
    elsif constraint.blank?
      errors.add(:allowed_values, 'must not be blank')
    end
  end
end
