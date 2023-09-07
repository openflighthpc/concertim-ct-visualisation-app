class RemoveUnencryptedPasswordFromUsers < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO uma,public' }
    end

    remove_column :users, :fixme_encrypt_this_already_plaintext_password, :string, null: true, limit: 128, default: ""

    reversible do |dir|
      dir.down { execute 'SET search_path TO uma,public' }
    end
  end
end
