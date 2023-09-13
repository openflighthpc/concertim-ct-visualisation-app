class Metric
  class Definition

    MetricValue = Struct.new(:id, :value, keyword_init: true)

    def self.fetch(key)
      MEMCACHE.get(key)
    end

    def initialize(device_ids: [])
      @minmaxes = {}
      @selected_device_ids = device_ids || []
    end

    def values_for_devices_with_metric(metric)
      metric = metric.to_sym
      [].tap do |el|
        devices_with_metric(metric).each do |key, device|
          device.deep_symbolize_keys!
          next if device_stale?(device)
          next if device[:metrics].nil? || device[:metrics][metric].nil?
          value = device[:metrics][metric][:value]
          el << MetricValue.new(id: device[:id], value: value) if value
        end
      end
    end

    def metric_definitions
      parser = URI::Parser.new
      fetch_many(device_keys).each do |_, device|
        device.deep_symbolize_keys!
        next if device_stale?(device)
        next if device[:metrics].nil?
        device[:metrics].values.each do |metric|
          next if metric[:nature] != 'volatile'
          mname = metric[:name]
          mval = metric[:value]
          minmax(mname, mval)
          if MetricType.get(mname).nil?
            units = metric[:units].nil? ? nil : metric[:units].force_encoding('utf-8')
            mt = MetricType.new(
              :id => mname,
              :name => mname,
              :units => units,
              :range => :auto,
            )
            MetricType.register(mt)
          end
        end
      end

      metrics = MetricType.all.sort { |a, b| a.id <=> b.id }
      [metrics, @minmaxes]
    end

    private

    # Return true if the device is considered stale.
    #
    # +device+ is a hash of the device data stored in the interchange.
    #
    # A device is only considered to be stale if it has not yet been processed by meryl.
    def device_stale?(device)
      device[:mtime].nil?
    end

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

    def devices_with_metric(metric)
      fetch_many(device_keys_with_metric(metric) & ids_to_interchange_keys(@selected_device_ids))
    end

    def device_keys_with_metric(metric)
      @device_keys_with_metric ||= fetch("meryl:metric:#{metric}")
    end

    def ids_to_interchange_keys(ids_array)
      ids_array.map{|oneId| "hacor:device:#{oneId}"}
    end
  end
end
