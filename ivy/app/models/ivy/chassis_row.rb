module Ivy
  class ChassisRow < Ivy::Model

    self.table_name = 'chassis_rows'

    ###############################
    #
    # Associations
    #
    ###############################

    # All three of these chassis associations are the same. Because the naming of this
    # association wasn't kept consistent in legacy, it's not consistent here. 
    #
    #  chassis            -> the one we should be using
    #  base_chassis       -> The one legacy wants to see (needs to be deprecated)
    #  indirect_chassis   -> here so that we can chain queries from device
    #
    belongs_to :chassis, foreign_key: :base_chassis_id
    # belongs_to :base_chassis, foreign_key: :base_chassis_id, class_name: "Ivy::Chassis"
    belongs_to :indirect_chassis, foreign_key: :base_chassis_id, class_name: "Ivy::Chassis"

    has_many :slots, ->{ order(:chassis_row_location) }, dependent: :destroy
    has_one :slot, dependent: :destroy

  end
end
