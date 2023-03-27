class CreateMecaSchema < ActiveRecord::Migration[7.0]
  def up
    execute 'CREATE SCHEMA meca'
  end

  def down
    execute 'DROP SCHEMA meca'
  end
end
