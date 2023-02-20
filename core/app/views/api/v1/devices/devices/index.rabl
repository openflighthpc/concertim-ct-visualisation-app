object @devices
node do |device|
  partial('api/v1/devices/devices/show', object: device)
end
