class CreateDeviceVolumeDetails < ActiveRecord::Migration[7.1]
  def change
    create_table :device_volume_details, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string :availability_zone
      t.boolean :bootable
      t.boolean :encrypted
      t.boolean :read_only
      t.integer :size
      t.string :volume_type

      t.timestamps
    end
  end
end
