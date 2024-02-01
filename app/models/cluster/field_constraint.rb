# Cluster::FieldConstraint models a single constraint that can be defined for a
# cluster type's parameters.
#
# The validations in this class validate the defintion (schema) of the
# constraint.  They do not validate the user-provided value against the
# constraint.  Validations for that can be found in the Cluster::Field class.
#
# The schema for defining a constraint is:
#
#   {
#     <constraint type>: <constraint definition>,
#     "description": <constraint description>
#   }
#
# The <constraint type> will be made available under the attribute, `type`.
# The <constraint description> will be made available under the attribute
# `description`.
# The <constraint definition> will be made available under the attribute
# `definition`.
#
# The format of `definition` will depend on the `type`.  E.g., for a `type` of
# `allowed_pattern`, `definition` will be a string that is also a valid regular
# expression.  For a `type` of `length`, `definition` will be an object with
# `min` and/or `max` properties which themseleves are numbers.
#
# Currently, the supported constraints and their definitions are as documented
# at
# https://docs.openstack.org/heat/latest/template_guide/hot_spec.html#parameter-constraints.
#
# Whilst custom constraints are supported, zero custom constraints are
# currently implemented.
class Cluster::FieldConstraint
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Map from constraint id to valiator.
  VALIDATORS = {
    length: 'LengthConstraintValidator',
    range: 'RangeConstraintValidator',
    modulo: 'ModuloConstraintValidator',
    allowed_pattern: 'AllowedPatternConstraintValidator',
    allowed_values: 'AllowedValuesConstraintValidator',
  }.freeze

  # The ID of the constraint.  For standard constraints this will be the same
  # as its type, e.g., `length`, or `allowed_pattern`.  For custom constraints
  # this will the same as its definition, e.g., `glance.image` or `net_cidr`.
  attribute :id, :string
  attribute :description, :string
  attribute :type, :string
  attribute :definition

  validates :id, presence: true
  validates :type, presence: true
  validates :definition, presence: true

  validate :validate_definition_format

  ############################
  #
  # Public Instance Methods
  #
  ############################

  def initialize(**kwargs)
    type = kwargs.keys.find {|key| key != "description" }
    if type
      definition = kwargs.delete(type)
    end
    id = type
    if type == "custom_constraint"
      id = definition
    end

    super(kwargs.merge(id: id, type: type, definition: definition))
  end

  def name
    type
  end

  # Return an ActiveModel::Validator that can be used to validate against this
  # constraint.
  def validator
    v = VALIDATORS[id.to_sym]
    return nil if v.nil?
    klass = self.class.const_get(v)
    klass.new(description: description, definition: definition)
  end

  private

  ############################
  #
  # Private Instance Methods
  #
  ############################

  def validate_definition_format
    self.send("validate_#{type}_format") if self.respond_to?("validate_#{type}_format", true)
  end

  def validate_modulo_format
    unless definition.is_a?(Hash)
      errors.add(:definition, 'must be a hash')
      return
    end

    step = definition["step"]
    if step.nil?
      errors.add(:modulo, 'must contain step details')
    elsif ![Integer, Float].include?(step.class)
      errors.add(:modulo, 'step must be a valid number')
    end
    offset = definition["offset"]
    if offset && ![Integer, Float].include?(offset.class)
      errors.add(:modulo, 'offset must be empty or a valid number')
    end
  end

  def validate_range_format
    blank = true
    definition.each do |key, value|
      unless [Integer, Float].include?(value.class)
        errors.add(:range, "#{key} must be a valid number")
      end
      blank = false unless value.nil?
    end
    errors.add(:range, "must have a max and/or min") if blank
  end

  def validate_length_format
    blank = true
    definition.each do |key, value|
      unless [Integer, Float].include?(value.class)
        errors.add(:length, "#{key} must be a valid number")
      end
      blank = false unless value.nil?
    end
    errors.add(:length, "must have a max and/or min") if blank
  end

  def validate_allowed_pattern_format
    begin
      Regexp.new(definition)
    rescue
      errors.add(:allowed_pattern, 'must be valid regex')
    end
  end

  def validate_allowed_values_format
    if !definition.is_a?(Array)
      errors.add(:allowed_values, 'must be an array of values')
    elsif definition.blank?
      errors.add(:allowed_values, 'must not be blank')
    end
  end

  class LengthConstraintValidator
    def initialize(description:, definition:)
      @description = description
      @min = definition["min"]
      @max = definition["max"]
    end

    def validate(field)
      length = field.value.length
      unless (!@min || length >= @min) && (!@max || length <= @max)
        error_message = @description
        if error_message.blank?
          error_message = "must be "
          error_message << "at least #{@min} characters" if @min
          error_message << "#{ " and " if @min}at most #{@max} characters" if @max
        end
        field.errors.add(:value, error_message)
      end
    end
  end

  class RangeConstraintValidator
    def initialize(description:, definition:)
      @description = description
      @min = definition["min"]
      @max = definition["max"]
    end

    def validate(field)
      number = field.value.to_f
      unless (!@min || number >= @min) && (!@max || number <= @max)
        error_message = @description
        if error_message.blank?
          error_message = "must be "
          error_message << "at least #{@min}" if @min
          error_message << "#{ " and " if @min}at most #{@max}" if @max
        end
        field.errors.add(:value, error_message)
      end
    end
  end

  class AllowedPatternConstraintValidator
    def initialize(description:, definition:)
      @description = description
      @pattern = definition
    end

    def validate(field)
      regexp = Regexp.new(@pattern)
      unless regexp.match?(field.value) && !regexp.match(field.value).to_s.blank?
        error_message = @description || "must match pattern #{@pattern}"
        field.errors.add(:value, error_message)
      end
    end
  end

  class ModuloConstraintValidator
    def initialize(description:, definition:)
      @description = description
      @offset = definition["offset"]
      @step = definition["step"]
    end

    def validate(field)
      number = field.value.to_f
      unless (@offset && number == @offset) || (@offset ? number - @offset : number) % @step == 0
        error_message = @description || "must match step of #{@step}#{" and offset of #{@offset}" if @offset}"
        field.errors.add(:value, error_message)
      end
    end
  end

  class AllowedValuesConstraintValidator
    def initialize(description:, definition:)
      @description = description
      @allowed_values = definition
    end

    def validate(field)
      return if @allowed_values.empty?

      unless @allowed_values.include?(field.value) || (field.type == "number" && @allowed_values.include?(field.value.to_f))
        error_message = @description || "must be chosen from one of the drop down options"
        field.errors.add(:value, error_message)
      end
    end
  end
end
