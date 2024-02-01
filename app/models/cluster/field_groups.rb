class Cluster::FieldGroups
  attr_reader :fields, :groups, :ungrouped_fields

  def initialize(cluster, groups, fields)
    @groups = groups.map do |group_definition|
      Cluster::FieldGroup.new(**group_definition.symbolize_keys)
    end
    @fields = fields.map do |id, details|
      Cluster::Field.new(id, details)
    end

    @ungrouped_fields = []
    @fields.each do |field|
      group = @groups.detect { |g| g.contains_field?(field.id) }
      if group.nil?
        @ungrouped_fields << field
      else
        group.add(field)
      end
    end
    @ungrouped_fields.sort_by!(&:order)
  end

  def each(&block)
    @groups.each(&block)
  end
end
