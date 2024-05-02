class LimitsPresenter < Presenter

  def grouped_limits
    disk_max = o["maxTotalVolumeGigabytes"] == -1 ? "GB / No limit" :  " / #{o["maxTotalVolumeGigabytes"]}GB"
    ram_max = o["maxTotalRAMSize"] == -1 ? "MB / No limit" :  " / #{o["maxTotalRAMSize"] /1024.0}MB"
    %w(maxTotalCores maxTotalInstances maxTotalVolumes).each {|max| o[max] = "No limit" if o[max] == -1 }
    {
      total_vcpus: "#{o["totalCoresUsed"]} / #{o["maxTotalCores"]}",
      total_disk_space: "#{o["totalGigabytesUsed"]}#{disk_max}",
      total_ram: "#{o["totalRAMUsed"] / 1024.0}#{ram_max}",
      servers: "#{o["totalInstancesUsed"]} / #{o["maxTotalInstances"]}",
      volumes: "#{o["totalVolumesUsed"]} / #{o["maxTotalVolumes"]}"
    }
  end
end
