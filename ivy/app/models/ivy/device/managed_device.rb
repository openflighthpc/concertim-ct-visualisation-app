module Ivy
  class Device
    class ManagedDevice < NetworkedDevice

      MANAGEMENT_APPLIANCE_TYPES = %w{ mia isla } unless defined? ManagedDevice::MANAGEMENT_APPLIANCE_TYPES
    end
  end
end
