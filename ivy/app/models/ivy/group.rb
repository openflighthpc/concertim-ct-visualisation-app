module Ivy
  class Group < ApplicationRecord
    self.table_name = "groups"

    ########################
    #
    # Public Instance Methods
    #
    ########################

    public

    def group_devices
      Ivy::Device.where(id: member_ids)
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
      Ivy::MemcacheGroupFacade.new(interchange_key)
    end

    def interchange_key
      "hacor:group:#{id}"
    end

  end
end
