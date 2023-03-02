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
    has_one :chassis, through: :chassis_row
    has_one :cluster, through: :chassis


    ###############################
    #
    # Validations
    #
    ###############################

    validates :chassis_row, presence: true
    validates :chassis_row_location, numericality: { integer_only: true }, allow_nil: false 
    validates :chassis_row_location, uniqueness: { scope: :chassis_row_id }
    validate :device_valid?


    ####################################
    #
    # Delegation
    #
    ####################################

    delegate :compatible_with_device?, to: :chassis


    ####################################
    #
    # Class Methods
    #
    ####################################

    # Dynamically create association builders and getters for device types.
    #
    # XXX Do we still want these?  Is there anywhere that they do something
    # other than build_device?
    Device.types.each do |device_type|
      prepend(Module.new do
        extend ActiveSupport::Concern
        prepended do
          association_name = device_type.name.demodulize.underscore
          has_one association_name.to_sym, class_name: device_type.name, dependent: :destroy
          eval <<-END
            def build_#{association_name}(*args)
              instance_eval("def device\n #{association_name}\n end")
              super
            end
          END
        end
      end)
    end


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
