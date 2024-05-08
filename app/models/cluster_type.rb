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

class ClusterType < ApplicationRecord
  ############################
  #
  # Validations
  #
  ############################

  validates :name,
    presence: true,
    length: { maximum: 255 }

  validates :description,
    presence: true,
    length: { maximum: 1024 }

  # the id provided by cluster builder
  validates :foreign_id,
    presence: true,
    uniqueness: true

  validates :version,
    presence: true

  # fields will require some sophisticated validation
  validates :fields,
    presence: true

  validates :order,
    presence: true,
    numericality: true

  validate :valid_fields_structure?

  # The custom configuration for this cluster type.
  # For example:
  # ````
  #   {
  #     "clustername": {
  #       "constraints": [
  #         {
  #           "description": "Cluster name must be between 6 and 255 characters",
  #           "length": {
  #             "max": 255,
  #             "min": 6
  #           }
  #         },
  #         {
  #           "allowed_pattern": "[a-zA-Z]+[a-zA-Z0-9\\-\\_]*",
  #           "description": "Cluster name can contain only alphanumeric characters, hyphens and underscores"
  #         }
  #       ],
  #       "default": "mycluster",
  #       "description": "The name your cluster should be given",
  #       "label": "Cluster name",
  #       "type": "string",
  #       "order": 1
  #     },
  #     "count": {
  #       "constraints": [
  #         {
  #           "description": "Number of replicas cannot be less than one",
  #           "range": {
  #             "min": 1
  #           }
  #         }
  #       ],
  #       "default": 3,
  #       "description": "How many replicas should your cluster contain?",
  #       "label": "Number of database replicas",
  #       "type": "number",
  #       "order": 2
  #     },
  #     "database_flavour": {
  #       "constraints": [
  #         {
  #           "allowed_values": [
  #             "MariaDB",
  #             "PostgreSQL",
  #             "Cassandra"
  #           ]
  #         }
  #       ],
  #       "default": "PostgreSQL",
  #       "description": "Which database flavour do you want?",
  #       "label": "Database flavour",
  #       "type": "string",
  #       "order": 3
  #     },
  #     "node_flavour": {
  #       "constraints": [
  #         {
  #           "allowed_values": [
  #             "m1.small",
  #             "m1.medium",
  #             "m1.large",
  #             "m1.xxlarge",
  #             "m1.xxxlarge"
  #           ]
  #         }
  #       ],
  #       "default": "m1.small",
  #       "description": "Which flavour should be be used for the database servers?",
  #       "label": "Node flavour",
  #       "type": "string".
  #       "order": 4
  #     }
  #   }
  # ```
  #

  # ####################################
  # #
  # # Scopes
  # #
  # ####################################

  default_scope { order(name: :asc) }

  # ####################################
  # #
  # # Public Instance Methods
  # #
  # ####################################

  def to_param
    foreign_id
  end

  def descriptive_name
    name ? "#{name} (#{foreign_id})" : foreign_id
  end

  private

  # ####################################
  # #
  # # Private Instance Methods
  # #
  # ####################################

  def valid_fields_structure?
    return unless fields

    combined_errors = []
    fields.each do |id, details|
      begin
        field = Cluster::Field.new(id, details)
        unless field.valid?
          field_errors = field.errors
          value_errors = field_errors.delete(:value)
          value_errors.each { |error| field_errors.add(:default, error) } if value_errors && field.default
          if field_errors.any?
            combined_errors << "field '#{field.id}' is invalid: #{field_errors.full_messages.join("; ")}"
          end
        end
      rescue => error
        combined_errors << "field invalid: #{error}"
      end
    end
    errors.add(:fields, combined_errors.join(". ")) if combined_errors.any?
  end
end
