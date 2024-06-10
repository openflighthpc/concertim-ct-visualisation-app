#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

class Cluster
  include ActiveModel::API

  # The field from which the cluster name will be copied if such a field
  # exists.
  NAME_FIELD = 'clustername'.freeze

  ####################################
  #
  # Properties
  #
  ####################################

  attr_accessor :cluster_type
  attr_accessor :team
  attr_accessor :name
  attr_reader :selections

  ####################################
  #
  # Validations
  #
  ####################################

  validates :cluster_type,
            presence: true

  validates :team,
            presence: true

  validate :team_has_enough_compute_units?

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

  def initialize(cluster_type:, team: nil, name: nil, cluster_params: nil, selections: {})
    @cluster_type = cluster_type
    @team = team
    @name = name
    @selections = selections
    @cluster_params = cluster_params
  end

  def field_groups
    @field_groups ||= Cluster::FieldGroups.new(self, cluster_type.field_groups, cluster_type.fields)
  end

  def fields
    return @fields if @fields

    @fields = self.field_groups.fields
    @fields.each { |field| field.value = @cluster_params[field.id] } if @cluster_params
    @fields
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
    return unless cluster_type

    fields.each do |field|
      unless field.valid?
        errors.add(field.label, field.errors.messages_for(:value).join("; "))
      end
    end
  end

  def team_has_enough_compute_units?
    if team_id && !team.meets_cluster_compute_unit_requirement?
      errors.add(:team, "Has insufficient compute_units to launch a cluster")
    end
  end
end
