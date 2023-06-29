class Fleece::Cluster
  include ActiveModel::API

  # The associated Fleece::ClusterType.  Not using `type` has that has special
  # meaning for ActiveRecord::Base and may have special meaning for ActiveModel
  # too.
  attr_accessor :kind
  attr_accessor :name
  attr_accessor :fields

  validates :kind,
    presence: true

  validates :name,
            presence: true,
            length: { minimum: 6, maximum: 255 },
            format: { with: /\A[a-zA-Z][a-zA-Z0-9\-_]*\z/,
                      message: "can contain only alphanumeric characters, hyphens and underscores" }

  validate :valid_fields?

  def initialize(kind:, name:, cluster_params: nil)
    @kind = kind
    @name = name
    @fields = kind.fields.map { |id, details| Fleece::Cluster::Field.new(id, details) }.sort_by(&:order)
    fields.each { |field| field.value = cluster_params[field.id] unless field.immutable } if cluster_params
  end

  def type_id
    @kind.kind
  end

  def field_values
    {}.tap do |field_values|
      fields.each do |field|
        field_values[field.id] = field.value
      end
    end
  end

  private

  def valid_fields?
    fields.each do |field|
      unless field.valid?
        errors.add(field.label, field.errors.messages_for(:value).join("; "))
      end
    end
  end
end
