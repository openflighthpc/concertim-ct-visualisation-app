class CreateUsersTable < ActiveRecord::Migration[7.0]
  def change
    create_table 'users' do |t|
      t.string :login, limit: 80, null: false
      t.string :firstname, limit: 56, null: false
      t.string :surname, limit: 56, null: false
      t.text :email, null: false, default: ''
      t.string :encrypted_password, limit: 128, null: false, default: ''
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet :current_sign_in_ip
      t.inet :last_sign_in_ip
      t.integer :sign_in_count, null: false, default: 0
      t.text :authentication_token
      t.datetime :remember_created_at
      t.string :reset_password_token, limit: 255
      t.datetime :reset_password_sent_at
      t.boolean :root, null: false, default: false

      t.timestamps
    end
    add_index 'users', :login, unique: true
    add_index 'users', :email, unique: true
  end
end
