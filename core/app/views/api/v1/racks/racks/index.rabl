object @racks
node do |rack|
  partial('api/v1/racks/racks/show', :object => rack)
end
