class MetricType
  attr_accessor :name, :id, :range, :units

  def initialize(opts = {})
    self.name = opts[:name]
    self.id = opts[:id]
    self.range = opts[:range] || :none
    self.units = opts[:units] || ""
  end

  class << self
    def get(id)
      @registry[id]
    end

    def register(metric_type)
      @registry[metric_type.id] = metric_type
    end

    def all
      @registry.values
    end
  end

  @registry = {}
end
