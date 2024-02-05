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
end