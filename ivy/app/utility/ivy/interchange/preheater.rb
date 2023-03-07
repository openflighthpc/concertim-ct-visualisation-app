require "phoenix/cache/preheater"
require 'phoenix/cache/locking'

module Ivy
  module Interchange
    # Preheats the interchange with the specified classes.
    #
    # Preheating means populates the interchange in the appropriate way.  This
    # is done when the application starts and when a connection to the
    # interchange is re-established.
    class Preheater < Phoenix::Cache::Preheater

      heatables(
        :DataSourceMap,
        :Device,
        # :Chassis,
        # :HwRack,
        # :ApplianceConfig,
      )

      wait_for()

      cache_wrapper MEMCACHE

      logger MEMCACHE.logger
    end
  end
end
