class CreateDeviceNetworkDetails < ActiveRecord::Migration[7.1]
  def change
    create_table :device_network_details, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.boolean :admin_state_up
      t.string :dns_domain
      t.boolean :l2_adjacency
      t.integer :mtu
      t.boolean :port_security_enabled
      t.boolean :shared
      t.string :qos_policy

      t.timestamps
    end
  end
end
