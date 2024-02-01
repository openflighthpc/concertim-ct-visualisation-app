# Cluster::FieldConstraints models a collection of constraints for a single
# cluster type parameter (aka Cluster::Field).
class Cluster::FieldConstraints
  def initialize(field, constraints)
    @field = field
    @constraints = constraints
  end

  def empty?
    @constraints.empty?
  end

  def map(&block)
    @constraints.map(&block)
  end

  def has_constraint?(id)
    !!self[id]
  end

  def [](id)
    @constraints.find { |c| c.id == id.to_s }
  end
end
