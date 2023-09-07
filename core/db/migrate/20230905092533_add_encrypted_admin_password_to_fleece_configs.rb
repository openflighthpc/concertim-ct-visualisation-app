class AddEncryptedAdminPasswordToFleeceConfigs < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO public' }
    end

    add_column :fleece_configs, :admin_foreign_password, :string

    reversible do |dir|
      dir.down { execute 'SET search_path TO public' }
    end
  end
end
