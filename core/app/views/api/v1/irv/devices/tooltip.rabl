object @device
attribute description: "Description"

glue(:template) do
  attribute vcpus: "VCPUs"
  attribute ram: "RAM (GB)"
  attribute disk: "Disk (GB)"
end

node do |device|
  device.metadata.transform_keys { |key| key.humanize }
end

node do |device|
  attrs = device.template.attributes.slice("name", "description")
  attrs.transform_keys { |key| "Template #{key}" }
end
