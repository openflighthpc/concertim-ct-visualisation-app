class AddEncryptedPasswordToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :foreign_password, :string
  end
end
