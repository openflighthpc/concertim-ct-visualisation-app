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
        total_ram: "#{total_ram_mb / 1024} / #{quotas["ram"] /1024}GB",
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
