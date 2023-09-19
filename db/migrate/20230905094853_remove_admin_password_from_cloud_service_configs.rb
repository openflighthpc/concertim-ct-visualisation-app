class RemoveAdminPasswordFromCloudServiceConfigs < ActiveRecord::Migration[7.0]
  def change
    remove_column :cloud_service_configs, :admin_password, :string, null: true, limit: 255
  end
end
