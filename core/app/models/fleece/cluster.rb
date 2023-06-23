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
            length: { maximum: 255 }

  def initialize(kind:, name:, cluster_params: nil)
    @kind = kind
    @name = name
    @fields = kind.fields
    @fields.each { |field| field.value = cluster_params[field.id] unless field.immutable } if cluster_params
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
end
