class RemoveAdminPasswordFromFleeceConfigs < ActiveRecord::Migration[7.0]
  def change
    remove_column :fleece_configs, :admin_password, :string, null: true, limit: 255
  end
end
