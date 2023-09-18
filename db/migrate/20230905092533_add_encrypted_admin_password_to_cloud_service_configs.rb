class AddEncryptedAdminPasswordToCloudServiceConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :cloud_service_configs, :admin_foreign_password, :string
  end
end
