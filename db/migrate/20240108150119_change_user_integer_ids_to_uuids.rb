# Migrate the users table from a sequential integer primary key to a UUID
# primary.
#
# There are a couple of foreign keys to the users table that need to be
# respected during this migraiton.  They are from the rackview presets table
# and the allowlisted jwts table. A correct data migration would be somewhat
# involved and I'd like to avoid that.
#
# As we have not yet had a production release and recreating the rack view
# presets manually is simple, we simplify the data migration by deleting all of
# the rack view presets and rely on users to manually recreate.
#
# Similarly, all allowlisted jwts are deleted.  The assumption being that any
# clients making use of them will transparently notice that they don't work
# anymore and reauthenticate.
class ChangeUserIntegerIdsToUuids < ActiveRecord::Migration[7.0]
  class RackviewPreset < ActiveRecord::Base; end
  class AllowlistedJwt < ActiveRecord::Base; end

  def up
    # Remove all rack view presets.
    RackviewPreset.reset_column_information
    RackviewPreset.destroy_all
    AllowlistedJwt.reset_column_information
    AllowlistedJwt.destroy_all

    # Remove the foreign key columns (well it should be a foreign key).
    remove_column 'rackview_presets', 'user_id'
    remove_reference 'racks', 'user'
    remove_reference 'allowlisted_jwts', 'user'

    # Add new UUID primary key and remove old integer primary key.
    add_column 'users', :uuid, :uuid, default: "gen_random_uuid()", null: false
    change_table 'users' do |t|
      t.remove :id
      t.rename :uuid, :id
    end
    execute "ALTER TABLE users ADD PRIMARY KEY (id);" 

    # Add back the removed foreign key columns.
    add_reference 'rackview_presets', 'user', null: true, foreign_key: { on_update: :cascade, on_delete: :cascade }, type: :uuid
    add_reference 'racks', 'user', null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }, type: :uuid
    add_reference 'allowlisted_jwts', 'user', null: false, foreign_key: { on_delete: :cascade }, type: :uuid
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
