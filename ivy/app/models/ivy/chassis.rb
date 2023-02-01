module Ivy
  class Chassis < Ivy::Model

    self.table_name = "base_chassis"

    include Ivy::Concerns::Templateable

    #######################
    #
    # Associations
    #
    #######################

    # The `rack` assocation needs to be `optional: true`.  The assocation is
    # inherited by `NonRackChassis` which obviously doesn't have a rack.  If
    # `optional: true` is not set, a `NonRackChassis` would never be valid.
    # Unfortunately, it isn't possible to set this association on the
    # subclasses with appropriate `optional` settings as it is used in `has_one
    # through:` relationship in `Device`.
    #
    # This mimics the behaviour that this association had in new-legacy where
    # `belongs_to` associations where optional by default.
    #
    # A better solution may be available, but I haven't found it.
    belongs_to :rack, :class_name => "Ivy::HwRack", optional: true

    #
    # Simple chassis relationship (one of everything)
    #
    has_one :chassis_row, ->{ order(:row_number) },
      class_name: 'Ivy::ChassisRow',
      dependent: :destroy,
      foreign_key: :base_chassis_id
    has_one :slot,   through: :chassis_row
    has_one :device, through: :slot

    #
    # Non-simple chassis relationship (multiple chassis_rows, muptiple slots, multiple devices)
    #
    has_many :chassis_rows, ->{ order(:row_number) },
      class_name: 'Ivy::ChassisRow',
      :dependent => :destroy,
      :foreign_key => :base_chassis_id
    has_many :slots,   :through => :chassis_rows, source: :slot
    has_many :devices, :through => :slots


    #######################
    #
    # Scopes
    #
    #######################

    scope :rackable_non_showable,
      -> {
        where("base_chassis.rack_id is null and base_chassis.show_in_dcrv is not true")
          .joins(:template)
          .where("templates.rackable = ?", 1)
      }
    scope :dcrvshowable, -> { where("rack_id is null and show_in_dcrv = true") }
    scope :modified_after, ->(timestamp) { where("modified_timestamp > ?", timestamp.to_i) }
  end
end
