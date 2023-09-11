class AddEncryptedAdminPasswordToConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :configs, :admin_foreign_password, :string
  end
end
