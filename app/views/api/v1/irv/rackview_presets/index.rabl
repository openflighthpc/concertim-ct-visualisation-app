object @presets
node do |preset|
  partial('api/v1/irv/rackview_presets/show', :object => preset)
end
