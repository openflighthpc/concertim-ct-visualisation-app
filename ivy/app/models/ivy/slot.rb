module Ivy
  class Slot < ApplicationRecord
    self.table_name = "slots"

    include Ivy::Concerns::LiveUpdate::Slot


    ####################################
    #
    # Associations
    #
    ####################################

    belongs_to :chassis_row, class_name: 'Ivy::ChassisRow'
    has_one :device, dependent: :destroy
    has_one :chassis, through: :chassis_row


    ###############################
    #
    # Validations
    #
    ###############################

    validates :chassis_row, presence: true
    validates :chassis_row_location, numericality: { integer_only: true }, allow_nil: false 
    validates :chassis_row_location, uniqueness: { scope: :chassis_row_id }, unless: ->(){ chassis_row_id.nil? }
    validate :device_valid?


    ####################################
    #
    # Delegation
    #
    ####################################

    delegate :compatible_with_device?, to: :chassis


    ############################
    #
    # Private Instance Methods
    #
    ############################

    private

    def device_valid?
      return if self.device.nil?
      return if self.device.valid?

      errors.add(:device, "Device invalid")
    end
  end
end
