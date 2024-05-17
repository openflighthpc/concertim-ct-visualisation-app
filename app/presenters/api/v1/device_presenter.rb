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
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

#
# Api::V1::DevicePresenter
#
# Device Presenter for the API
#
# NOTE: If this file starts becoming large / a bag of methods, split it out
# into seperate files within a `device_presenter` folder, grouped into domain
# categories, e.g., `device_presenter/location`.
module Api::V1
  class DevicePresenter < Presenter
    include Costed

    # Be selective about what attributes and methods we expose.
    delegate :id, :name, :description, :metadata, :status, :details, :type, to: :o

    # location returns the location of the device.  For devices in simple
    # chassis, the chassis's location is returned. Devices in complex chassis,
    # are blade servers in a blade enclosure, the location of blade server in
    # the enclosure is returned.
    def location
      if o.chassis.nil?
        # This should not longer be possible.
        raise TypeError, "device does not have a chassis"

      elsif o.chassis_simple?
        # A simple device/chassis.  It's location is the location of its
        # chassis.
        Api::V1::ChassisPresenter.new(o.chassis, h).location

      elsif o.chassis_complex?
        # A blade server.
        raise NotImplementedError, "Support for complex chassis is not implemented"

      else
        # We shouldn't get here.
        if Rails.env.development?
          raise "Unhandled device location for #{o.id}"
        else
          Rails.logger.warn("Unhandled device location: #{o.id}")
        end
        nil
      end
    end

    def template
      # XXX Consider using a presenter here too.
      o.template
    end

    def template_id
      template.id
    end

    def has_login_details?
      public_ips || private_ips || ssh_key || login_user
    end
  end
end
