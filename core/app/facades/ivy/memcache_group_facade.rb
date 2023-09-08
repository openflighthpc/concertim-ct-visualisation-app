#
# Ivy::MemcacheGroupFacade
#
# Memcache facade covering groups (whose keys are of the format 'hacor:group:1' etc.
#
module Ivy
  class MemcacheGroupFacade < Emma::MemcacheValueFacade

    UNKNOWN_GROUP = "Unknown Group"

    def name
      o[:name] || UNKNOWN_GROUP
    end


    #
    # member_ids
    #
    def member_ids
      members.map do |member_memcache_key|
        member_memcache_key.split(':').last
      end
    end

  end
end
