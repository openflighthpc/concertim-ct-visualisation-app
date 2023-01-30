module Meca
  class Metric
    class Definition
      def self.fetch(key)
        MEMCACHE.get(key)
      end

      def initialize(opts={})
        @types = MetricType.dynamic
        @custom_types = {}
        @minmaxes = {}
        # @selected_device_ids = opts.delete(:device_ids)
        # @selected_tagged_devices_ids = opts.delete(:tagged_devices_ids)
      end

      def metric_definitions
        parser = URI::Parser.new
        fetch_many(device_keys).each do |_, device|
          # only consider devices for which we've had a metric update within the last 90s
          # devices older than this should be considered stale
          next if device[:mtime].nil? || (Time.now - device[:mtime]) > 90
          next if device[:metrics].nil?
          device[:metrics].values.each do |metric|
            next if metric[:nature] != 'volatile'
            mname = metric[:name]
            mval = metric[:value]
            minmax(mname, mval)
            if MetricType.get(mname).nil? && @custom_types[mname].nil?
              @custom_types[mname] = MetricType.new(:id => mname,
                                                    :name => mname,
                                                    :units => parser.escape(metric[:units]).force_encoding('utf-8'),
                                                    :range => :auto,
                                                    :type => :dynamic,
                                                    :selectable => true)
            end
          end
        end

        metrics = (@types + @custom_types.values.sort{|a,b|a.id<=>b.id})

        return [metrics, @minmaxes]
      end

      private

      def fetch(key)
        self.class.fetch(key)
      end     

      def fetch_many(keys)
        MEMCACHE.get_multi(*keys)
      end     

      def device_keys
        @device_keys ||= fetch('hacor:devices')
      end

      def minmax(k,v)
        v = v.to_i
        h = (@minmaxes[k] ||= {})
        if h[:max].nil? || h[:max] < v
          h[:max] = v
        end
        if h[:min].nil? || h[:min] > v
          h[:min] = v
        end
      end

    end
  end
end
