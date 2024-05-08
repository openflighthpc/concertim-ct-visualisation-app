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

class Cluster::FieldGroup

  # Format and options are driven by content defined in
  # https://docs.openstack.org/heat/latest/template_guide/hot_spec.html#parameter-groups-section

  ####################################
  #
  # Properties
  #
  ####################################

  attr_reader :label, :description
  attr_accessor :selected

  ####################################
  #
  # Public Instance Methods
  #
  ####################################

  def initialize(label:, description:, parameters:, optional: nil)
    @label = label
    @description = description
    @parameters = parameters || []
    @optional = optional
    @fields = {}
    @selected = optional? ? @optional["default"] : true
  end

  # contains_field? returns true if the group is configured to contain the given field_id.
  def contains_field?(field_id)
    @parameters.include?(field_id)
  end

  # add adds the given field to this group.
  def add(field)
    field.group = self
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

  def optional?
    @optional.present?
  end

  def selected?
    !!selected
  end

  def selection_label
    @optional["label"]
  end

  def selection_form_name
    @optional["name"]
  end
end
