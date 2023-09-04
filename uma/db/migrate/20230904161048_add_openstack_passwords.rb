class AddOpenstackPasswords < ActiveRecord::Migration[7.0]
  def up
    Uma::User.reset_column_information
    Uma::User.all.each do |user|
      user.openstack_password = user.fixme_encrypt_this_already_plaintext_password
      user.save
    end
  end

  def down
    Uma::User.reset_column_information
    Uma::User.all.each do |user|
      user.openstack_password = nil
      user.save
    end
  end
end
