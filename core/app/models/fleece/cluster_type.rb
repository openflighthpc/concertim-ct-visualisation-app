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

  validates :kind,
    presence: true,
    uniqueness: true

  # fields will require some sophisticated validation
  validates :fields,
    presence: true

  # The custom configuration for this cluster type.
  #
  # Currently, nothing is custom about this, all cluster types have a single
  # item of configuration which is the number of nodes.
  #
  # This will change to allow each ClusterType to specify custom configuration.
  # Perhaps this will be stored as a JSON blob in the database.  The new
  # cluster form will construct the form inputs based on the custom
  # configuration.
  #
  # Example configuration might look like:
  #
  # ```
  # [
  #   {
  #     "id": "number_of_headnodes",
  #     "text": "Enter the number of headnodes",
  #     "description": "...",
  #     "default": 1,
  #     "input": {
  #       "type": "number"
  #     },
  #     "validation": {
  #       "type": "integer",
  #       "minimum": 1,
  #     }
  #   },
  #   {
  #     "id": "redundancy",
  #     "text": "How much redundancy do you want?",
  #     "description": "...",
  #     "default": "high",
  #     "input": {
  #       "type": "select",
  #       "options": [
  #         {"text": "High",   "value": "high"},
  #         {"text": "Medium", "value": "medium"},
  #         {"text": "Low",    "value": "low"},
  #       ]
  #     },
  #     "validation": {
  #       "type": "string",
  #       "enum": ["high", "medium", "low"],
  #     }
  #   },
  # ]
  # ```
  #


  # ####################################
  # #
  # # Public Instance Methods
  # #
  # ####################################

  def fields(raw: false)
    if raw
      super()
    else
      @_fields ||=
        begin
          raw_fields = super()
          if raw_fields.nil?
            nil
          else
            raw_fields.map { |field| Fleece::ClusterType::Field.new(field) }
          end
        end
    end
  end

  def fields=(raw_fields)
    if raw_fields.nil? || raw_fields.blank?
      super(nil)
    else
      super(raw_fields)
    end
  end
end
