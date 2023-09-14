object @templates
node do |template|
  partial('api/v1/templates/show', :object => template)
end
