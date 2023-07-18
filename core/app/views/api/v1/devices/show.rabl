object @device

attributes :id, :name, :description, :metadata, :status
attributes :location

child(:template, if: @include_template_details) do
  extends 'api/v1/templates/show'
end
