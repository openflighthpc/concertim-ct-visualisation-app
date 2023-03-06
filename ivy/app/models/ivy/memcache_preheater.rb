require "phoenix/cache/preheater"
require 'phoenix/cache/locking'

module Ivy
  class MemcachePreheater < Phoenix::Cache::Preheater

    heatables(
      # :DataSourceMap,
      :Device,
      # :Chassis,
      # :HwRack,
      # :ApplianceConfig,
    )

    wait_for()

    cache_wrapper MEMCACHE

    logger MEMCACHE.logger

    extend Phoenix::Cache::Locking

    class << self

      # Preheat the given klass and instances
      #
      # +instances+ defaults to +klass.all+.
      #
      # Both the interchange list and individual interchange keys are updated,
      # e.g., both `hacor:devices` and `hacor:device:ID`.
      def preheat_interchange(klass, instances=nil)
        logger.info("Preheating model #{klass.to_s}")
        start = Time.now.to_i

        instances ||= klass.all
        failed_ids = instances.map(&:id)
        retries = 10

        # try to preheat a number of times
        while retries > 0 && failed_ids.size > 0
          # lock the global list, if it exists, and update the elements
          if klass.interchange_list.nil? 
            preheat_items(nil, instances, klass, failed_ids)
          else
            locked_modify(klass.interchange_list, :default => []) do |list|
              preheat_items(list, instances, klass, failed_ids)
            end
          end
          retries -= 1
          sleep 3 if retries > 0 && failed_ids.size > 0
        end

        # pass back the failed ids, if any
        time_taken = Time.now.to_i - start
        failed_ids.each {|id| logger.warn("Failed to preheat #{klass.to_s}:#{id}")}
        @logger.info("Completed model #{klass.to_s} in #{time_taken} secs")
        failed_ids
      end

      # add_list_interchange adds the given instance to the correct interchange
      # list. E.g., the following will update the `hacor:devices` interchange
      # list.
      #
      #   add_list_interchange(Device.first)
      #
      # The instance should also be added to the interchange, e.g., by calling
      # `heat`.
      def add_list_interchange(obj, klass = nil)
        klass ||= obj.class
        locked_modify(klass.interchange_list, :default => []) do |list|
          klass.store_list_in_interchange(list, obj)
        end
      end

      # Add a single instance to the interchange.
      def heat(obj)
        locked_modify(obj.memcache_key, :default => {}) do |data|
          obj.store_self_in_interchange(data)
        end
      end

      private

      def cache
        cache_wrapper
      end

      # Attempt to store each instance in interchange; update +list+ with each
      # success.
      def preheat_items(list, instances, klass, failed_ids)
        instances.each do |instance|
          begin
            if failed_ids.include?(instance.id)
              klass.store_list_in_interchange(list, instance) unless list.nil?
              success = true
              # XXX Want to use `heat` here. but return values are not consistent.
              locked_modify(instance.memcache_key, :default => {}) do |data|
                success = instance.store_self_in_interchange(data)
              end
              failed_ids.delete(instance.id) if success
            end
          rescue Exception => e
            # we'll try again next time
            logger.warn("#{e.message} - #{e.backtrace.inspect}")
          end
        end
      end
    end
  end
end
