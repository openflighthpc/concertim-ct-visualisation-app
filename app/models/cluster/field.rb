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

class Cluster::Field
  include ActiveModel::Validations

  # Format and options are driven by content defined in
  # https://docs.openstack.org/heat/latest/template_guide/hot_spec.html#parameters-section

  ####################################
  #
  # Properties
  #
  ####################################

  attr_accessor :id
  attr_accessor :order
  attr_accessor :type
  attr_accessor :label
  attr_accessor :description
  attr_accessor :default
  attr_accessor :hidden
  attr_accessor :immutable
  attr_accessor :value
  attr_accessor :group
  attr_reader :constraints

  ############################
  #
  # Validations
  #
  ############################

  validates :type,
            presence: true,
            inclusion: { in: %w(string number comma_delimited_list json boolean) }

  validates :id, :label, :order,
            presence: true
  validates :value,
    presence: true,
    if: -> { group.nil? || group.selected? }

  validate :valid_number?, if: -> { value && type == "number" }
  validate :valid_json?, if: -> { value && type == "json" }
  validate :valid_boolean?, if: -> { value && type == "boolean" }
  validate :validate_constraint_formats
  validate :validate_constraints

  ############################
  #
  # Public Instance Methods
  #
  ############################

  def initialize(id, details)
    @id = id
    details = default_details.merge(details)
    details.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end
    self.default ||= step[:min]
    self.label ||= id.gsub("_", " ").capitalize
    self.value = default
  end

  def constraints=(constraints)
    @constraints = Cluster::FieldConstraints.new(constraints.map { |c| Cluster::FieldConstraint.new(**c) })
  end

  def allowed_values?
    constraints.has_constraint?(:allowed_values)
  end

  def allowed_values
    constraints[:allowed_values]&.definition
  end

  def step
    return {} unless type == "number"

    modulo_constraint = constraints[:modulo]
    return {} if modulo_constraint.nil?

    details = modulo_constraint.definition
    details[:min] = details["offset"] if details["offset"]
    details
  end

  private

  ############################
  #
  # Private Instance Methods
  #
  ############################

  def default_details
    {
      hidden: false,
      immutable: false,
      constraints: [],
    }
  end

  def valid_number?
    unless type == "number" && ([Float, Integer].include?(value.class) || /^-?\d*\.?\d+$/.match?(value))
      errors.add(:value, "must be a valid number")
    end
  end

  def valid_json?
    return unless type == "json"

    begin
      JSON.parse(value)
    rescue
      errors.add(:value, "must be valid JSON")
    end
  end

  def valid_boolean?
    unless type == "boolean" && ["f", "false", false, "0", 0, "off", "t", "true", true, "1", 1, "on"].include?(value)
      errors.add(:value, "must be a valid boolean")
    end
  end

  def validate_constraint_formats
    constraints.each do |constraint|
      next if constraint.valid?
      constraint.errors.full_messages_for(constraint.id).each do |error_message|
        errors.add(:constraint, error_message)
      end
    end
  end

  def validate_constraints
    if value
      @constraints.each do |constraint|
        unless constraint.valid?
          Rails.logger.info("Skipping constraint #{constraint.id}: invalid definition: #{constraint.errors.details}")
          next
        end
        validator = constraint.validator
        if validator.nil?
          Rails.logger.info("Skipping constraint #{constraint.id}: no validator defined")
          next
        end
        validator.validate(self)
      end
    end
  end
end
