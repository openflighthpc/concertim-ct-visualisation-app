class AddPlaintextPasswordToUsers < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.string :fixme_encrypt_this_already_plaintext_password, null: true, limit: 128, default: ""
    end
  end
end
