class PopulateEncryptedAdminPasswords < ActiveRecord::Migration[7.0]
  def up
    Fleece::Config.reset_column_information
    Fleece::Config.all.each do |config|
      config.admin_openstack_password = config.admin_password
      config.save!
    end
  end

  def down
    Fleece::Config.reset_column_information
    Fleece::Config.all.each do |config|
      config.admin_openstack_password = nil
      config.save(validate: false)
    end
  end
end
