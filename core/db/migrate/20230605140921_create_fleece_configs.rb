class CreateFleeceConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :fleece_configs do |t|
      t.string :host_name,    limit: 255, null: false
      t.inet :host_ip,                    null: false
      t.string :username,     limit: 255, null: false
      t.string :password,     limit: 255, null: false
      t.integer :port, default: 5000,     null: false
      t.string :project_name, limit: 255, null: false
      t.string :domain_name,  limit: 255, null: false

      t.timestamps
    end
  end
end
