class CreateDeviceComputeDetails < ActiveRecord::Migration[7.1]
  def change
    create_table :device_compute_details, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string :public_ips
      t.string :private_ips
      t.string :ssh_key
      t.string :login_user
      t.jsonb :volume_details, default: {}, null: false

      t.timestamps
    end

    add_column :devices, :details_type, :string
    add_column :devices, :details_id, :uuid
  end
end
