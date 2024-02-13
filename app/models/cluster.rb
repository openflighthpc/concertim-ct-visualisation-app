class Cluster
  include ActiveModel::API

  ####################################
  #
  # Properties
  #
  ####################################

  attr_accessor :cluster_type
  attr_accessor :team
  attr_accessor :name
  attr_accessor :fields
  attr_accessor :field_groups

  ####################################
  #
  # Validations
  #
  ####################################

  validates :cluster_type,
            presence: true

  validates :team,
            presence: true

  validate :team_has_enough_credits?

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

  def initialize(cluster_type:, team: nil, name: nil, cluster_params: nil)
    @cluster_type = cluster_type
    @team = team
    @name = name
    @field_groups = Cluster::FieldGroups.new(self, cluster_type.field_groups, cluster_type.fields)
    @fields = @field_groups.fields
    fields.each { |field| field.value = cluster_params[field.id] } if cluster_params
  end

  def type_id
    @cluster_type.foreign_id
  end

  def team_id
    @team&.id
  end

  def field_values
    {}.tap do |field_values|
      fields.each do |field|
        field_values[field.id] = field.value
      end
    end
  end

  def add_field_error(field_or_id, error)
    field =
      if field_or_id.is_a?(String)
        fields.detect { |f| f.id == field_id }
      else
        field_or_id
      end
    return nil if field.nil?
    field.errors.add(:value, error)
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

  def team_has_enough_credits?
    if team_id && Team.meets_cluster_credit_requirement.where(id: team_id).empty?
      errors.add(:team, "Has insufficient credits to launch a cluster")
    end
  end
end
