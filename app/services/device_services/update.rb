#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

#
# DeviceServices::Update
#
# Extracted from controller action. The responsibility when updating a device is that you also need to 
# update the chassis (the same form as the device has information such as the template id which goes on
# the device's chassis). 
#
# There is additional responsibility in here to update the name of the chassis if it doesn't have one. This
# should not be required, but if a chassis ever got into our system without a name (something our system should
# not allow) then this would mean that the device's chassis could never be saved. We did observe this with 
# sensors in #22948.
#
module DeviceServices
  class Update
    def self.call(device, device_params, location_params, details_params, user)
      chassis = device.chassis
      location = device.location
      device.update(device_params)

      if location && !location_params.blank?
        DeviceServices::Move.call(location, location_params, user)
        location.save
      end

      if details_params
        if !details_params[:type] || details_params[:type] == device.details_type
          device.details.update(details_params.except(:type))
        else
          # It's forbidden to change device details type after creation
          # We set details to nil here so that validation on Device can return a
          # sensible error message (cannot be changed...), and we don't need to
          # worry about handling an invalid type being specified here.
          device.details = nil
        end
      end

      return [device, chassis, location]
    end
  end
end
