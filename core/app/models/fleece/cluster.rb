class Fleece::Cluster
  include ActiveModel::API

  # The associated Fleece::ClusterType.  Not using `type` has that has special
  # meaning for ActiveRecord::Base and may have special meaning for ActiveModel
  # too.
  attr_accessor :kind
  attr_accessor :cluster_params

  validates :kind,
    presence: true

  def initialize(kind:, **cluster_params)
    @kind = kind
    @cluster_params = cluster_params
    @kind.fields.each do |field|
      singleton_class.class_eval { attr_accessor field.id }
      self.send("#{field.id}=", cluster_params[field.id] || field.default)
    end
  end

  def type_id
    @kind.kind
  end
end
