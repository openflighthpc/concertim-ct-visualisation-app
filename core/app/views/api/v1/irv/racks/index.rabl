collection @racks
node do |rack|
  partial('api/v1/irv/racks/show', :object => rack)
end
