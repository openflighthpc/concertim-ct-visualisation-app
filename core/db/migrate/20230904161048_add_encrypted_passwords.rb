class AddEncryptedPasswords < ActiveRecord::Migration[7.0]
  def up
    User.reset_column_information
    User.all.each do |user|
      user.foreign_password = user.fixme_encrypt_this_already_plaintext_password
      user.save!
    end
  end

  def down
    User.reset_column_information
    User.all.each do |user|
      user.foreign_password = nil
      user.save
    end
  end
end
