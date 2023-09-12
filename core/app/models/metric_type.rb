class MetricType
  attr_accessor :name, :id, :range, :selectable, :units, :type, :prioritized

  def initialize(opts = {})
    self.name = opts[:name]
    self.id = opts[:id]
    self.range = opts[:range] || :none
    self.selectable = (opts[:selectable] != false)
    self.units = opts[:units] || ""
    self.type = opts[:type] || :dynamic
    self.prioritized = (opts[:prioritized] == true)
  end

  class << self
    def get(id, type=nil)
      m = @registry[id]
      return nil if m.nil?
      return m   if type.nil?
      return m   if m.type == type
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
