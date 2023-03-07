module Meca
  class Metric
    class Definition

      MetricValue = Struct.new(:id, :value, keyword_init: true)

      def self.fetch(key)
        MEMCACHE.get(key)
      end

      def initialize(opts={})
        @types = MetricType.dynamic
        @custom_types = {}
        @minmaxes = {}
        @selected_device_ids = opts.delete(:device_ids) || []
        @selected_tagged_devices_ids = opts.delete(:tagged_devices_ids) || []
      end

      def values_for_devices_with_metric(metric)
        [].tap do |el|
          non_tagged_devices_with_metric(metric).each do |key, device|
            next if device[:mtime].nil? || (Time.now - device[:mtime]) > 90 || device[:metrics].nil? || device[:metrics][metric].nil?
            value = device[:metrics][metric][:value]
            el << MetricValue.new(id: device[:id], value: value) if value
          end
        end
      end

      def values_for_chassis_with_metric(metric)
        [].tap do |el|
          tagged_devices_with_metric(metric).each do |key, device|
            next if device[:mtime].nil? || (Time.now - device[:mtime]) > 90 || device[:metrics].nil? || device[:metrics][metric].nil?
            value = device[:metrics][metric][:value]
            el << MetricValue.new(id: device[:chassis_id], value: value) if value
          end
        end
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

      def non_tagged_devices_with_metric(metric)
        fetch_many(device_keys_with_metric(metric) & ids_to_interchange_keys(@selected_device_ids))
      end

      def tagged_devices_with_metric(metric)
        fetch_many(device_keys_with_metric(metric) & ids_to_interchange_keys(@selected_tagged_devices_ids))
      end

      def device_keys_with_metric(metric)
        @device_keys_with_metric ||= fetch("meryl:metric:#{metric}")
      end

      def ids_to_interchange_keys(ids_array)
        ids_array.map{|oneId| "hacor:device:#{oneId}"}
      end

    end
  end
end
