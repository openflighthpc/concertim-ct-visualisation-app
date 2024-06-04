object @device

attributes :id, :name, :description, :metadata, :status, :cost, :location, :type
attribute cloud_created_at: :created_at

child(:template, if: @include_full_template_details) do
  extends 'api/v1/templates/show'
end

glue :details do |details|
  extends "api/v1/devices/details/#{details.class.name.split('::').last.underscore}"
end

attribute :template_id, unless: @include_full_template_details
