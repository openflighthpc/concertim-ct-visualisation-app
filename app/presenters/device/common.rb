#
# Device::Common
#
# Methods common to all device-based presenters
#
# NOTE: If this file starts becoming large / a bag of methods, split 
# it out into seperate files within this folder, grouped into domain categories.
# 
class Device
  module Common

    #
    # device_type
    #
    # Humanized version of the class. Either hands off to the specific device
    # presenter for that device type or just calls the humanizer utility
    # class.
    #
    def device_type
      TypeHumanizer.humanize(o.respond_to?(:type) ? o.type : o.class.name)
    end
  end
end
