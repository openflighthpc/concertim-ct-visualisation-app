class CreateUsersTable < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :login, limit: 80, null: false
      t.string :name, limit: 56, null: false
      t.text :email, default: "", null: false
      t.string :encrypted_password, limit: 128, default: "", null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet :current_sign_in_ip
      t.inet :last_sign_in_ip
      t.integer :sign_in_count, default: 0, null: false
      t.text :authentication_token
      t.datetime :remember_created_at
      t.string :reset_password_token, limit: 255
      t.datetime :reset_password_sent_at
      t.boolean :root, default: false, null: false
      t.string :project_id, limit: 255
      t.string :cloud_user_id
      t.decimal :cost, default: "0.0", null: false
      t.date :billing_period_start
      t.date :billing_period_end
      t.string :foreign_password

      t.timestamps
    end

    add_index :users, :login, unique: true
    add_index :users, :email, unique: true
    add_index :users, :project_id, unique: true, where: "NOT NULL"
  end
end
