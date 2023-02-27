object @devices
node do |device|
  partial('api/v1/devices/show', object: device)
end
