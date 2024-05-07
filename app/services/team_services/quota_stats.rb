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

module TeamServices
  class QuotaStats
    def self.call(team, quotas)
      new.call(team, quotas)
    end

    def call(team, quotas)
      @team = team
      {
        total_vcpus: "#{total_vcpus} / #{quotas["cores"]}",
        total_disk_space: "#{total_disk_space} / #{quotas["gigabytes"]}GB",
        total_ram: "#{total_ram_mb / 1024.0} / #{quotas["ram"] /1024.0}GB",
        servers: "#{servers.count} / #{quotas["instances"]}",
        volumes: "#{volumes.count} / #{quotas["volumes"]}",
        networks: "#{networks.count} / #{quotas["network"]}"
      }
    end

    private

    def servers
      @team.devices.joins(:template).where(details_type: "Device::ComputeDetails")
    end

    def volumes
      @team.devices.where(details_type: "Device::VolumeDetails")
    end

    def networks
      @team.devices.where(details_type: "Device::NetworkDetails")
    end

    def total_vcpus
      servers.sum("templates.vcpus")
    end

    def total_ram_mb
      servers.sum("templates.ram")
    end

    def total_disk_space
      server_disk_space = servers.sum("templates.disk")
      volumes_disk_space = volumes.reduce(0) {|sum, volume| sum + (volume.details.size || 0)}
      server_disk_space + volumes_disk_space
    end
  end
end
