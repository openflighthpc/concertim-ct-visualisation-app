class PopulateEncryptedAdminPasswords < ActiveRecord::Migration[7.0]
  def up
    CloudServiceConfig.reset_column_information
    CloudServiceConfig.all.each do |config|
      config.admin_foreign_password = config.admin_password
      config.save!
    end
  end

  def down
    CloudServiceConfig.reset_column_information
    CloudServiceConfig.all.each do |config|
      config.admin_foreign_password = nil
      config.save(validate: false)
    end
  end
end
