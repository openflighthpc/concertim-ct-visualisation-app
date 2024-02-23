object @device

attributes :id, :name, :description, :metadata, :status, :cost, :location

child(:template, if: @include_full_template_details) do
  extends 'api/v1/templates/show'
end

glue :details do |details|
  extends "api/v1/devices/details/#{details.class.name.split('::').last.underscore}"
  #node :type do |details|
  #  details.class.name
  #end
end

attribute :template_id, unless: @include_full_template_details
