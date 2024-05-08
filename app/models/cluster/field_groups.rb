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

class Cluster::FieldGroups
  attr_reader :fields, :groups

  def initialize(cluster, groups, fields)
    @groups = groups.map do |group_definition|
      Cluster::FieldGroup.new(**group_definition.symbolize_keys)
    end
    @groups.each do |group|
      next if cluster.selections.nil?
      next unless group.optional?
      group.selected = cluster.selections[group.selection_form_name]
    end
    @fields = fields.map do |id, details|
      Cluster::Field.new(id, details)
    end

    ungrouped_fields = []
    @fields.each do |field|
      group = @groups.detect { |g| g.contains_field?(field.id) }
      if group.nil?
        ungrouped_fields << field
      else
        group.add(field)
      end
    end

    unless ungrouped_fields.empty?
      ungrouped_group = Cluster::FieldGroup.new(
        label: 'Cluster Parameters',
        description: '',
        parameters: ungrouped_fields.sort_by(&:order).map(&:id),
      )
      ungrouped_fields.each { |g| ungrouped_group.add(g) }
      @groups.unshift(ungrouped_group)
    end
  end

  def each(&block)
    @groups.each(&block)
  end

  def optional_selection_form_names
    @groups.select(&:optional?).map(&:selection_form_name)
  end
end
