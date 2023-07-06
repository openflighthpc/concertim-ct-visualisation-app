class Fleece::Cluster
  include ActiveModel::API

  ####################################
  #
  # Properties
  #
  ####################################

  attr_accessor :cluster_type
  attr_accessor :name
  attr_accessor :fields

  ####################################
  #
  # Validations
  #
  ####################################

  validates :cluster_type,
    presence: true

  validates :name,
            presence: true,
            length: { minimum: 6, maximum: 255 },
            format: { with: /\A[a-zA-Z][a-zA-Z0-9\-_]*\z/,
                      message: "can contain only alphanumeric characters, hyphens and underscores" }

  validate :valid_fields?

  ####################################
  #
  # Public Instance Methods
  #
  ####################################

  def initialize(cluster_type:, name: nil, cluster_params: nil)
    @cluster_type = cluster_type
    @name = name
    @fields = cluster_type.fields.map { |id, details| Fleece::Cluster::Field.new(id, details) }.sort_by(&:order)
    fields.each { |field| field.value = cluster_params[field.id] } if cluster_params
  end

  def type_id
    @cluster_type.kind
  end

  def field_values
    {}.tap do |field_values|
      fields.each do |field|
        field_values[field.id] = field.value
      end
    end
  end

  private

  ####################################
  #
  # Private Instance Methods
  #
  ####################################

  def valid_fields?
    fields.each do |field|
      unless field.valid?
        errors.add(field.label, field.errors.messages_for(:value).join("; "))
      end
    end
  end
end
