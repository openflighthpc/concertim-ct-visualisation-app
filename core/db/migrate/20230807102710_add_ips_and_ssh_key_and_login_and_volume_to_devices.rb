class AddIpsAndSshKeyAndLoginAndVolumeToDevices < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    add_column :devices, :public_ips, :string
    add_column :devices, :private_ips, :string
    add_column :devices, :ssh_key, :string
    add_column :devices, :login_user, :string
    add_column :devices, :volume_details, :jsonb, null: false, default: {}

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
