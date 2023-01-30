module Ivy
  class Group < Ivy::Model
    self.table_name = "groups"

    ########################
    #
    # Scopes 
    #
    ########################

    # Groups pertaining to non physical devices
    scope :system_non_physical_device_groups, -> { where("immutable = true AND (virtual_servers_in_hosts IS NOT NULL or virtual_server IS NOT NULL)") }

    ########################
    #
    # Public Class Methods
    #
    ########################
    def self.excluding_system_non_physical_device_groups
      ids = self.system_non_physical_device_groups.pluck(:id)
      where("id NOT IN (?)", [0,*ids])
    end

  end
end
