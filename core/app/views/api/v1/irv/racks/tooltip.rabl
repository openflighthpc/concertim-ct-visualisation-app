object @rack
node "Owner", if: current_user.root? do |rack|
  rack.user.name
end

node do |rack|
  rack.metadata.transform_keys { |key| key.humanize }
end

