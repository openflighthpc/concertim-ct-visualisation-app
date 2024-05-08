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

class PopulateDeviceComputeDetails < ActiveRecord::Migration[7.1]

  class Device < ApplicationRecord
    belongs_to :details, polymorphic: true
  end

  class ::Device::Details < ApplicationRecord
    self.abstract_class = true
  end

  class ::Device::ComputeDetails < ::Device::Details
  end

  def up
    Device.reset_column_information
    Device.all.each do |device|
      device.details = ::Device::ComputeDetails.new(
        login_user: device.login_user,
        public_ips: device.public_ips,
        private_ips: device.private_ips,
        ssh_key: device.ssh_key,
        volume_details: device.volume_details
      )
      device.save!
    end
  end

  def down
    ::Device::ComputeDetails.delete_all
  end
end
