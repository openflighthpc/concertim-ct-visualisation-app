object @threshold
attributes :id, :name, :enabled, :breach_value
attribute :metric_text => :metric
node(:colour, :if => lambda { |t| t.simple? }) { |threshold| '#ff0000' }
child(:ranges => :ranges) do
  attributes :id, :name, :upper_bound, :colour
end
