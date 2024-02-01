class Cluster::Field
  include ActiveModel::Validations

  # Format and options are driven by content defined in
  # https://docs.openstack.org/heat/latest/template_guide/hot_spec.html#parameters-section

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
  validate :validate_modulo_constraint, if: -> { should_validate_constraint?(:modulo) }
  validate :validate_range_constraint,  if: -> { should_validate_constraint?(:range) }
  validate :validate_length_constraint, if: -> { should_validate_constraint?(:length) }
  validate :validate_pattern,           if: -> { should_validate_constraint?(:allowed_pattern) }
  validate :validate_allowed_value,     if: -> { should_validate_constraint?(:allowed_values) }

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

  def constraints=(constraints)
    @constraints = Cluster::FieldConstraints.new(self, constraints.map { |c| Cluster::FieldConstraint.new(**c) })
  end

  def allowed_values?
    constraints.has_constraint?(:allowed_values)
  end

  def allowed_values
    constraints[:allowed_values]&.definition
  end

  def step
    return {} unless type == "number"

    modulo_constraint = constraints[:modulo]
    return {} if modulo_constraint.nil?

    details = modulo_constraint.definition
    details[:min] = details["offset"] if details["offset"]
    details
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

  def should_validate_constraint?(constraint_type)
    # Only validate against a constraint if we have a value and the constraint
    # is defined for this field and its definition is valid.
    value && @constraints.has_constraint?(constraint_type) && @constraints[constraint_type].valid?
  end

  def validate_modulo_constraint
    return unless type == "number"

    constraint = constraints["modulo"]
    number = value.to_f
    offset = constraint.definition["offset"]
    step = constraint.definition["step"]
    unless (offset && number == offset) || (offset ? number - offset : number) % step == 0
      error_message = constraint.description || "must match step of #{step}#{" and offset of #{offset}" if offset}"
      errors.add(:value, error_message)
    end
  end

  def validate_range_constraint
    return unless type == "number"

    constraint = constraints["range"]
    number = value.to_f
    min = constraint.definition["min"]
    max = constraint.definition["max"]
    unless (!min || number >= min) && (!max || number <= max)
      error_message = constraint.description
      if error_message.blank?
        error_message = "must be "
        error_message << "at least #{min}" if min
        error_message << "#{ " and " if min}at most #{max}" if max
      end
      errors.add(:value, error_message)
    end
  end

  def validate_length_constraint
    return unless %w(string comma_delimited_list json).include?(type)

    constraint = constraints["length"]
    length = value.length
    min = constraint.definition["min"]
    max = constraint.definition["max"]
    unless (!min || length >= min) && (!max || length <= max)
      error_message = constraint.description
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
    pattern = constraint.definition
    reg = Regexp.new(pattern)
    unless reg.match?(value) && !reg.match(value).to_s.blank?
      error_message = constraint.description || "must match pattern #{pattern}"
      errors.add(:value, error_message)
    end
  end

  def validate_allowed_value
    constraint = constraints["allowed_values"]
    allowed_values = constraint.definition
    return if allowed_values.empty?

    unless allowed_values.include?(value) || (type == "number" && allowed_values.include?(value.to_f))
      error_message = constraint.description || "must be chosen from one of the drop down options"
      errors.add(:value, error_message)
    end
  end
end
