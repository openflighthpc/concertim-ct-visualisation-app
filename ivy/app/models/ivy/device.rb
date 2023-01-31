module Ivy
  class Device < Ivy::Model
    self.table_name = "devices"


    ####################################
    #
    # Constants 
    #
    ####################################


    ####################################
    #
    # Associations
    #
    ####################################

    belongs_to :slot
    has_one :chassis_row, through: :slot, class_name: 'Ivy::ChassisRow'

    #
    # A device can have a relationship with a chassis in one of two ways:
    #
    # * A direct relationship, where base_chassis_id on devices joins straight to the base_chassis table
    # * An indirect relationship, through slots => chassis_rows => base_chassis
    #
    # A direct relationship indicates that the device is a "tagged" device - unfortunately
    # doing things this way means the relationship between a device and a chassis can't
    # be implemented in a simple way. Instead, we have two relationships (one for each of
    # the two bullet points above) and a convinience method within the device class
    # called "chassis" that works out which to call.
    #
    belongs_to :direct_chassis, class_name:  "Ivy::Chassis", foreign_key: :base_chassis_id
    has_one :indirect_chassis, through: :chassis_row, class_name: "Ivy::Chassis"

    #
    # similar technique to chassis has been applied to the rack relationship, as this is
    # based on the rack relationship.
    #
    has_one :direct_rack, through: :direct_chassis, source: :rack
    has_one :indirect_rack, through: :indirect_chassis, source: :rack


    ####################################
    #
    # Properties
    #
    ####################################


    ####################################
    #
    # Hooks 
    #
    ####################################


    ####################################
    #
    # Validations 
    #
    ####################################


    ####################################
    #
    # Delegation 
    #
    ####################################


    ####################################
    #
    # Defaults 
    #
    ####################################


    ####################################
    #
    # Class Methods
    #
    ####################################

    def self.types
      @types ||= [Ivy::Device]
    end


    ####################################
    #
    # Instance Methods
    #
    ####################################

    # 
    # has_direct_chassis
    #
    # Some devices (tagged ones) have a direct relationship with their
    # chassis. This is indicated by the "base_chassis_id" column on the 
    # device table being present.
    #
    def has_direct_chassis?
      !base_chassis_id.nil?
    end

    #
    # chassis
    # 
    # Infers whether this device has a direct or indirect association
    # with a chassis, and returns the appropriate association. This
    # method should be used *Sparingly*. Rails cannot bestow all of 
    # its nifty association powers to you if you're not referring to
    # associations directly.
    #
    def chassis(reload = false)
      if has_direct_chassis?
        direct_chassis
      else
        indirect_chassis
      end
    end

    #
    # rack
    #
    # As with chassis, infers the rack of this device based on whether
    # it has a direct or indirect chassis.
    #
    def rack
      if has_direct_chassis?
        direct_rack
      else
        indirect_rack
      end
    end

    ####################################
    #
    # Private Instance Methods
    #
    ####################################

  end
end

# XXX Consider replacing this with an inherited hook.
Dir["#{File.dirname(__FILE__)}/device/**.rb"].each do |d|
  file_name = File.basename(d, '.rb')
  require "ivy/device/#{file_name}"
  unless [ 'sensor' ].include? file_name
    Ivy::Device.types << "Ivy::Device::#{file_name.classify}".constantize
  end
end
