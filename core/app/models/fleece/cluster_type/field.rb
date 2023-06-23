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
  attr_accessor :value

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
            inclusion: { in: [true, false] }

  validates :immutable,
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
    self.default ||= step["min"]
    self.value = default
  end

  def allowed_values?
    allowed_values.any?
  end

  def allowed_values
    @_allowed_values ||= find_constraint("allowed_values")
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
      required: true,
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

    find_constraint("range")
  end

  def required_length
    return {} unless %w[string json comma_delimited_list].include?(type)

    required = find_constraint("length")
    required.keys.each do |key|
      required["#{key}length".to_sym] = required.delete(key)
    end

    required
  end

  def step
    return {} unless type == "number"

    details = find_constraint("modulo")
    return {} if details.empty?

    details[:min] = details.delete("offset") if details["offset"]
    details
  end

  def allowed_pattern
    return {} unless type == "string"

    pattern = find_constraint("allowed_pattern")
    return {} if pattern.empty?

    # This is some strange hacky stuff to prevent the regex being escaped when rendered. Must be a better way?
    {pattern: [pattern].to_s[2..-4]}
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
    constraints.map {|constraint| constraint["description"]}.join(". ")
  end

  def valid_value?(value)
    true
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

  def default_matches_type
    if default && !MAPPED_TYPE_CLASSES[type]&.include?(default.class)
      errors.add(:default, "must match value format")
    end
  end

  def defaults
    {
      hidden: false,
      immutable: false,
      constraints: {},
    }
  end

  def find_constraint(name)
    target_hash = constraints.find {|constraint| constraint.keys.include?(name) }
    target_hash ? target_hash[name] : {}
  end

  # if immutable, must have a default value
  # if hidden, must have a default value
end
