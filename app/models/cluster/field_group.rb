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
      f = @fields[p]
      if f.nil?
        Rails.logger.debug("Unable to find field #{p} in field group #{label}: assuming it is hardcoded and skipping it")
      else
        sorted_fields << f
      end
    end
    sorted_fields
  end

  def empty?
    fields.empty?
  end
end
