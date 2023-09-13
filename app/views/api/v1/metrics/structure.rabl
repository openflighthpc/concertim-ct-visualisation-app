collection @definitions
attributes :id, :name, :units
node :format do |metric|
  metric.units != '' ? "%s #{metric.units}" : "%s"
end
node :min do |metric|
  if metric.range != :none
    if metric.range == :auto
      unless @minmaxes[metric.id].nil?
        @minmaxes[metric.id][:min]
      end
    else
      metric.range.first
    end
  end
end
node :max do |metric|
  if metric.range != :none
    if metric.range == :auto
      unless @minmaxes[metric.id].nil?
        @minmaxes[metric.id][:max]
      end
    else
      metric.range.last
    end
  end
end
