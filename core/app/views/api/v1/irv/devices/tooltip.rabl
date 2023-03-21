object @device
attribute manufacturer: "Manufacturer"
attribute model: "Model"
attribute description: "Description"
attribute serial_number: "Serial number"
attribute asset_number: "Asset number"
glue(:template) do
  attribute template_name: "Template name"
  attribute description: "Template description"
end
