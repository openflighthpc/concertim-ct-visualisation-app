object @racks
node do |rack|
  partial('api/v1/racks/show', object: rack)
end
