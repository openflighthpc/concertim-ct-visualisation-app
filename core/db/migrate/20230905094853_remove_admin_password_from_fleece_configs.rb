class RemoveAdminPasswordFromFleeceConfigs < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO public' }
    end

    remove_column :fleece_configs, :admin_password, :string, null: true, limit: 255

    reversible do |dir|
      dir.down { execute 'SET search_path TO public' }
    end
  end
end
