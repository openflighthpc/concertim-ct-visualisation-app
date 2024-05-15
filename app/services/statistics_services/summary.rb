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

module StatisticsServices
  class Summary
    class << self
      def call
        {
          teams: teams_stats,
          racks: racks_stats,
          servers: servers_stats,
          volumes: volumes_stats,
          networks: networks_stats
        }
      end

      private

      def racks_stats
        {
          active: HwRack.where(status: %w(ACTIVE IN_PROGRESS)).count,
          inactive: HwRack.where(status: %w(STOPPED FAILED)).count
        }
      end

      def servers_stats
        servers = Instance.joins(:template).all
        {
          active: servers.where(status: %w(ACTIVE IN_PROGRESS)).count,
          inactive: servers.where(status: %w(FAILED STOPPED SUSPENDED)).count,
          total_vcpus: servers.sum("templates.vcpus"),
          total_ram:  "#{servers.sum("templates.ram") / 1024.0}GB",
          total_disk_space: "#{servers.sum("templates.disk")}GB"
        }
      end

      def volumes_stats
        volumes = Volume.joins(:template).all
        {
          active: volumes.where(status: %w(ACTIVE IN_PROGRESS)).count,
          inactive: volumes.where(status: %w(FAILED STOPPED AVAILABLE)).count,
          total_disk_space: "#{volumes.reduce(0) {|sum, volume| sum + (volume.details.size || 0)}}GB"
        }
      end

      def networks_stats
        networks = Network.joins(:template).all
        {
          active: networks.where(status: %w(ACTIVE IN_PROGRESS)).count,
          inactive: networks.where(status: %w(FAILED STOPPED)).count,
        }
      end

      def teams_stats
        {
          active: Team.count
        }
      end
    end
  end
end
