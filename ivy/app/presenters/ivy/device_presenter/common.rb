#
# Ivy::DevicePresenter::Common
#
# Methods common to all device-based presenters
#
# NOTE: If this file starts becoming large / a bag of methods, split 
# it out into seperate files within this folder, grouped into domain categories.
# 
module Ivy
  class DevicePresenter
    module Common

      #
      # device_type
      #
      # Humanized version of the class (so "RackChassis" becomes "Chassis" and so on). Either
      # hands off to the specific device presenter for that device type or just calls the humanizer
      # utility class. 
      #
      def device_type
        Ivy::TypeHumanizer.humanize(o.type)
      end
    end
  end
end
