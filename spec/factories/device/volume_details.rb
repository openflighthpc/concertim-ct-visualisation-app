FactoryBot.define do
  factory :device_volume_details, class: 'Device::VolumeDetails' do
    bootable { false }
    size { 1 }
    read_only { false }
  end
end
