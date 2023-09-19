class AddIpsAndSshKeyAndLoginAndVolumeToDevices < ActiveRecord::Migration[7.0]
  def change
    add_column :devices, :public_ips, :string
    add_column :devices, :private_ips, :string
    add_column :devices, :ssh_key, :string
    add_column :devices, :login_user, :string
    add_column :devices, :volume_details, :jsonb, null: false, default: {}
  end
end
