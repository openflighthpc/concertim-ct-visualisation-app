object @device

attributes :id, :name, :description
attributes :location
child(:template, if: @include_template_details) do
  attribute :id
  attribute template_name: :name
  attribute :description
end
