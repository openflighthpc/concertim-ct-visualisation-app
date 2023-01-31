class Api::V1::Metrics::BreachesController < Api::V1::Metrics::BaseController

  def index
    @chassis = Meca::Breach.breaching_chassis
    @devices = Meca::Breach.breaching_devices
    @sensors = Meca::Breach.breaching_sensors
    @racks   = Meca::Breach.breaching_racks
    @devices.each do |device| 
      if device.rack.nil?
        if params[:calling] == "dcpv"
          @chassis.push(device.chassis)
        end
      else
        # This causes all racks on the IRV with a breaching device to be
        # highlighted.  Its not necessary, the breaching devices are clearly
        # visible and is fugly.
        # @racks.push(device.rack)
      end
    end
    @chassis.uniq!
    @racks.uniq!
  end

end
