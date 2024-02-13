class PopulateDeviceComputeDetails < ActiveRecord::Migration[7.1]

  class Device < ApplicationRecord
    belongs_to :details, polymorphic: true
  end

  class ::Device::ComputeDetails < ApplicationRecord
  end

  def up
    Device.reset_column_information
    Device.all.each do |device|
      device.details = ::Device::ComputeDetails.new(
        login_user: device.login_user,
        public_ips: device.public_ips,
        private_ips: device.private_ips,
        ssh_key: device.ssh_key,
        volume_details: device.volume_details
      )
      device.save!
    end
  end

  def down
    ::Device::ComputeDetails.delete_all
  end
end
