class RemoveComputeFieldsFromDevice < ActiveRecord::Migration[7.1]
  def change
    remove_column :devices, :ssh_key, :string
    remove_column :devices, :login_user, :string
    remove_column :devices, :public_ips, :string
    remove_column :devices, :private_ips, :string
    remove_column :devices, :volume_details, :jsonb, default: {}, null: false
  end
end
