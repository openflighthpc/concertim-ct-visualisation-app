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
        servers = Device.joins(:template).where(details_type: "Device::ComputeDetails")
        {
          active: servers.where(status: %w(ACTIVE IN_PROGRESS)).count,
          inactive: servers.where(status: %w(FAILED STOPPED SUSPENDED)).count,
          total_vcpus: servers.sum("templates.vcpus"),
          total_ram:  "#{servers.sum("templates.ram")}GB",
          total_mem: "#{servers.sum("templates.disk")}GB"
        }
      end

      def volumes_stats
        volumes = Device.where(details_type: "Device::VolumeDetails")
        {
          active: volumes.where(status: %w(ACTIVE IN_PROGRESS)).count,
          inactive: volumes.where(status: %w(FAILED STOPPED SUSPENDED)).count,
          total_mem: "#{volumes.reduce(0) {|sum, volume| sum + (volume.details.size || 0)}}GB"
        }
      end

      def networks_stats
        networks = Device.where(details_type: "Device::NetworkDetails")
        {
          active: networks.where(status: %w(ACTIVE IN_PROGRESS)).count,
          inactive: networks.where(status: %w(FAILED STOPPED SUSPENDED)).count,

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

# active clusters
# active servers
# inactive clusters
# inactive servers
# used VCPUs
# used memory
# total teams