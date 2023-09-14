class PopulateEncryptedAdminPasswords < ActiveRecord::Migration[7.0]
  def up
    Config.reset_column_information
    Config.all.each do |config|
      config.admin_foreign_password = config.admin_password
      config.save!
    end
  end

  def down
    Config.reset_column_information
    Config.all.each do |config|
      config.admin_foreign_password = nil
      config.save(validate: false)
    end
  end
end
