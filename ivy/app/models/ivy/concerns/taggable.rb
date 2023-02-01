module Ivy
  module Concerns
    #
    # Taggable encapsulates common logic around "tagging" non-device objects
    # with a device.
    #
    # We want some objects to behave as if they are devices, that is things
    # against which metrics can be assigned, along with data such as model,
    # serial number and asset number.  Examples are racks and chassis.
    #
    # To achieve this we create a special "tagged device" and the rack/chassis
    # `belongs_to :tagged_device`.  The metrics are associated to that tagged
    # device and made available to the rack/chassis. This module encapsulates
    # the logic for doing this.
    #
    # XXX This module is only used by Rack.  Not by Chassis.  Chassis
    # duplicates much of the logic here.  Fix this.
    #
    module Taggable
      
      extend ActiveSupport::Concern
      
      included do
        belongs_to :tagged_device,
          class_name: "Ivy::Device::#{tagged_device_type}",
          dependent: :destroy
      end

      %w[
        model description serial_number cost_centre warranty_expiry_date
        initial_cost initial_purchase_date maintenance_expiry_date asset_number
        depreciation_date weight
      ].each do |attribute_name|
        define_method attribute_name do
          tagged_device.try(attribute_name)
        end
        
        setter = "#{attribute_name}="
        define_method setter do |value|
          tagged_device.send(setter, value)
        end
      end

      def metrics
        tagged_device.metrics
      end

      def value_for_metric(key)
        metrics[key] && metrics[key][:value]
      end

    end
  end
end
