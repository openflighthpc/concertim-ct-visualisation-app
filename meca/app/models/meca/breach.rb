module Meca
  class Breach < Meca::Model

    self.table_name = 'breaches'

    belongs_to :threshold, class_name: 'Meca::MecaThreshold'

    ########################
    #
    # Public Class Methods
    #
    ########################
    class << self

      def monitorable_ids
        # Meca::Breach.all(:fields => [:monitorable_id]).map(&:monitorable_id)
        # XXX Use 'pluck' method here once this model is in activerecord for a massive performance improvement.
        Meca::Breach.all.pluck(:monitorable_id)
      end

      def all_breaching
        Ivy::Device.where(id: monitorable_ids)
      end

      def breaching_chassis
        [].tap do |el|
          Meca::Breach.all_breaching.each do |dev|
            el << dev.chassis if dev.class == Ivy::Device::ChassisTaggedDevice
          end
        end
      end

      def breaching_devices
        Meca::Breach.all_breaching.select do |dev|
          Ivy::Device.types.include?(dev.class) && !dev.tagged?
        end
      end

      def breaching_sensors
        Meca::Breach.all_breaching.select do |dev|
          Ivy::Device::Sensor == dev.class
        end
      end

      # Used to hightlight the racks of zero u devices that are breaching.
      #
      # XXX Do we still want zero-u devices?
      def breaching_racks
        racks_array = []
        Meca::Breach.all_breaching.each do |dev|
          is_tagged_device = dev.class == Ivy::Device::ChassisTaggedDevice
          is_zero_u_chassis = dev.chassis.class == Ivy::Chassis::ZeroURackChassis

          if is_tagged_device && (is_zero_u_chassis)
            racks_array << dev.chassis.rack
          elsif Ivy::Device::RackTaggedDevice == dev.class
            racks_array << dev.rack
          end
        end
        racks_array
      end
    end
  end
end
