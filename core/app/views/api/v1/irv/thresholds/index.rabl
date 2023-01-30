object @thresholds
node do |threshold|
  partial('api/v1/irv/thresholds/show', :object => threshold)
end
