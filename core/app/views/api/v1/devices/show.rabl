object @device

attributes :id, :name, :description
attributes :location
child(:template, if: @include_template_details) do
  attribute :id
  attribute :name
  attribute :description
end
