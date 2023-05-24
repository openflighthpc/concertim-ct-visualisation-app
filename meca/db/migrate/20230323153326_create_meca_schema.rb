class CreateMecaSchema < ActiveRecord::Migration[7.0]
  def up
    execute 'CREATE SCHEMA IF NOT EXISTS meca'
  end

  def down
    execute 'DROP SCHEMA IF EXISTS meca'
  end
end
