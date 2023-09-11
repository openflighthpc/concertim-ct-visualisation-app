class AddEncryptedAdminPasswordToFleeceConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :fleece_configs, :admin_foreign_password, :string
  end
end
