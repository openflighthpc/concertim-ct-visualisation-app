class RemoveUnencryptedPasswordFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :fixme_encrypt_this_already_plaintext_password, :string, null: true, limit: 128, default: ""
  end
end
