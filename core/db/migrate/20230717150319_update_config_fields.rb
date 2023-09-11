class UpdateConfigFields < ActiveRecord::Migration[7.0]
  def change
    drop_table :configs

    create_table :configs do |t|
      t.string "admin_user_id", limit: 255, null: false
      t.string "admin_password", limit: 255, null: false
      t.string "admin_project_id", limit: 255, null: false
      t.integer "user_handler_port", default: 42356, null: false
      t.integer "cluster_builder_port", default: 42378, null: false
      t.string "host_url", limit: 255, null: false
      t.string "internal_auth_url", limit: 255, null: false

      t.timestamps
    end
  end
end
