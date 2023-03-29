#
# Ivy::HwRackServices::Create
#
# Attempts to build and save a new rack based on the passed-in parameters. Will also
# create its associated tagged device.
#
# It creates the tagged device automatically because:
#
# * We are explicitly setting the tagged_device_attribute[:name] 
# * A rack accepts_nested_attributs_for a tagged device
# * Rails does the rest.
#
module Ivy
  module HwRackServices
    class Create

      def self.call(rack_params)
        rack = Ivy::HwRack.new(rack_params)
        rack.save
        rack
      end

    end
  end
end
