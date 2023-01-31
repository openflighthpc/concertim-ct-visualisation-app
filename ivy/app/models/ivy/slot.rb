module Ivy
  class Slot < Ivy::Model
    self.table_name = "slots"

    ####################################
    #
    # Associations
    #
    ####################################

    belongs_to :chassis_row, class_name: 'Ivy::ChassisRow'
    has_one :device, dependent: :destroy
  end
end
