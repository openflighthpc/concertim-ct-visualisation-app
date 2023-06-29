class AddPlaintextPasswordToUsers < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO uma,public' }
    end

    change_table :users do |t|
      t.string :fixme_encrypt_this_already_plaintext_password, null: true, limit: 128, default: ""
    end

    reversible do |dir|
      dir.down { execute 'SET search_path TO uma,public' }
    end
  end
end
