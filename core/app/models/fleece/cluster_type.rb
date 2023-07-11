class Fleece::ClusterType < ApplicationRecord
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

  # fields will require some sophisticated validation
  validates :fields,
    presence: true

  validates :version,
    presence: true

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

end
