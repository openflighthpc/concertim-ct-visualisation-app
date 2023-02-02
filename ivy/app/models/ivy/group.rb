module Ivy
  class Group < Ivy::Model
    self.table_name = "groups"

    ########################
    #
    # Scopes 
    #
    ########################

    # Groups pertaining to non physical devices
    scope :system_non_physical_device_groups, -> {
      where("immutable = true AND (virtual_servers_in_hosts IS NOT NULL or virtual_server IS NOT NULL)")
    }
    scope :excluding_system_non_physical_device_groups, -> {
      excluding(system_non_physical_device_groups)
    }


    ########################
    #
    # Public Instance Methods
    #
    ########################

    public

    def group_sensors
      Ivy::Device::Sensor.where(:id => member_ids)
    end

    def group_devices
      Ivy::Device.where(:id => member_ids, :tagged => false)
    end

    # 
    # group_chassis
    #
    # Returns complex device chassis and non-rack device chassis
    #
    def group_chassis
      chassis = Ivy::Chassis.for_tagged_devices(member_ids) + Ivy::Chassis::NonRackChassis.for_devices(member_ids)
    end

    def member_ids
      raise NotImplementedError
    end

    def memcache_facade
      Ivy::MemcacheGroupFacade.new(memcache_key)
    end

    def memcache_key
      "hacor:group:#{id}"
    end

  end
end
