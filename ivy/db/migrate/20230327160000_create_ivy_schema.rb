class CreateIvySchema < ActiveRecord::Migration[7.0]
  def up
    execute 'CREATE SCHEMA IF NOT EXISTS ivy'
  end

  def down
    execute 'DROP SCHEMA IF EXISTS ivy'
  end
end
