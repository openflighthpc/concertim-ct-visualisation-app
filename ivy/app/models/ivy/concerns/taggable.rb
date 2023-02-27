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
        accepts_nested_attributes_for :tagged_device
        before_validation :set_tagged_device_defaults
        after_validation :fix_tagged_device_errors
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

      def set_tagged_device_defaults
        return unless new_record?
        return unless tagged_device.nil? || tagged_device.new_record?

        tagged_device = self.tagged_device || self.build_tagged_device

        tagged_device.tagged = true
        tagged_device.name ||= self.name
        tagged_device.build_data_source_map(
          :data_source_id=>1, :map_to_grid => 'unspecified', :map_to_cluster => 'unspecified',
          :map_to_host => tagged_device.name)
      end
      
      def fix_tagged_device_errors
        errors.messages.clone.each do |key, messages|
          if key.to_s.start_with? 'tagged_device'
            errors.delete(key)
            key.to_s.split('.').last.tap do |attribute_name|
              messages.each do |message|
                errors.add(attribute_name, message)
              end
            end
          end
        end
      end
      
    end
  end
end
