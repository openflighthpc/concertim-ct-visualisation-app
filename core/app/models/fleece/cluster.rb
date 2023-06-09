class Fleece::Cluster
  include ActiveModel::API

  # The associated Fleece::ClusterType.  Not using `type` has that has special
  # meaning for ActiveRecord::Base and may have special meaning for ActiveModel
  # too.
  attr_accessor :kind
  attr_accessor :name
  attr_accessor :nodes

  validates :kind,
    presence: true

  validates :name,
    presence: true,
    length: { maximum: 255 }

  validates :nodes,
    presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1_000 }
end
