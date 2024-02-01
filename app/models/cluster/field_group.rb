class Cluster::FieldGroup

  # Format and options are driven by content defined in
  # https://docs.openstack.org/heat/latest/template_guide/hot_spec.html#parameter-groups-section

  ####################################
  #
  # Properties
  #
  ####################################

  attr_reader :label, :description

  ####################################
  #
  # Public Instance Methods
  #
  ####################################

  def initialize(label:, description:, parameters:)
    @label = label
    @description = description
    @parameters = parameters || []
    @fields = {}
  end

  # contains_field? returns true if the group is configured to contain the given field_id.
  def contains_field?(field_id)
    @parameters.include?(field_id)
  end

  # add adds the given field to this group.
  def add(field)
    @fields[field.id] = field
  end

  # fields return the fields in the order defined by the parameters attribute.
  def fields
    sorted_fields = []
    @parameters.each do |p|
      sorted_fields << @fields[p]
    end
    sorted_fields
  end
end
