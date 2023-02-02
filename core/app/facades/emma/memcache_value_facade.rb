#
# Emma::MemcacheValueFacade
#
# * Special kind of facade for use with memcache values
# * Memcache value facades are all constructed with a memcache key
# * The subject of the facade (o) will be the has returned from memcache.
#
module Emma
  class MemcacheValueFacade < Emma::Facade

    #
    # initialize
    #
    def initialize(memcache_key)
      super MEMCACHE.get(memcache_key) || {} 
    end

    #
    # method_missing
    #
    # dynamically create methods for the first layer of keys in
    # a memcache value.
    #
    def method_missing(meth, *args, &block)
      o.keys.include?(meth.to_sym) ? o[meth.to_sym] : nil 
    end
  end
end
