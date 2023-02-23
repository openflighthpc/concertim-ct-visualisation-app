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
        # [:initial_purchase_date, :warranty_expiry_date, :maintenance_expiry_date, :depreciation_date].each do |attr|
        #   param = rack_params.delete(attr)
        #   rack_params[:tagged_device_attributes][attr] = param unless rack_params[:tagged_device_attributes][attr]
        # end
        #
        # [:serial_number, :asset_number, :initial_cost, :cost_centre, :weight].each do |attr|
        #   param = rack_params.delete(attr)
        #   rack_params[:tagged_device_attributes][attr] = param unless rack_params[:tagged_device_attributes][attr]
        # end

        rack = Ivy::Cluster.first.racks.build(rack_params)
        rack.save
        rack
      end

    end
  end
end
