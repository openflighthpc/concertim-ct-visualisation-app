# Migrate some tables from a sequential integer primary key to a UUID primary
# key.  Only tables which are simple to migrate are included here.  The other
# tables are migrated in different migrations to isolate their complexity.
class ChangeSomeIntegerIdsToUuids < ActiveRecord::Migration[7.0]
  def up
    enable_extension 'pgcrypto'

    %w(
      cloud_service_configs
      cluster_types
      data_source_maps
      rackview_presets
    ).each do |table|
      add_column table, :uuid, :uuid, default: "gen_random_uuid()", null: false
      change_table table do |t|
        t.remove :id
        t.rename :uuid, :id
      end
      execute "ALTER TABLE #{table} ADD PRIMARY KEY (id);" 
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
