class UpdateFleeceConfigFields < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO public' }
    end

    remove_column :fleece_configs, :host_name, :string, limit: 255, null: false
    remove_column :fleece_configs, :port, :integer, default: 5000, null: false
    remove_column :fleece_configs, :domain_name, :string, limit: 255, null: false
    remove_column :fleece_configs, :host_ip, :inet, null: false
    rename_column :fleece_configs, :project_name, :admin_project_id
    rename_column :fleece_configs, :username, :admin_user_id
    rename_column :fleece_configs, :password, :admin_password
    add_column :fleece_configs, :host_url, :string, limit: 255, null: false
    add_column :fleece_configs, :internal_auth_url, :string, limit: 255, null: false

    reversible do |dir|
      dir.down   { execute 'SET search_path TO public' }
    end
  end
end
