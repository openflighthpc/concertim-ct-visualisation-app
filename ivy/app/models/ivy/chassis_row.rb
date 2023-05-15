module Ivy
  class ChassisRow < ApplicationRecord

    self.table_name = 'chassis_rows'

    ###############################
    #
    # Associations
    #
    ###############################

    belongs_to :chassis, foreign_key: :base_chassis_id

    has_many :slots, ->{ order(:chassis_row_location) }, dependent: :destroy
    has_one :slot, dependent: :destroy


    ###############################
    #
    # Validations
    #
    ###############################

    validates :base_chassis_id, presence: true
    validates :row_number,
      numericality: { only_integer: true },
      uniqueness: { scope: :base_chassis_id },
      unless: ->{ base_chassis_id.nil? }


    ####################################
    #
    # Defaults
    #
    ####################################

    def set_defaults
      self.row_number = 
        if !chassis.nil? and !chassis.chassis_rows.nil?
          chassis.chassis_rows.count + 1
        else
          1
        end
    end

  end
end
