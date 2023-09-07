class CreateUmaSchema < ActiveRecord::Migration[7.0]
  def up
    execute 'CREATE SCHEMA IF NOT EXISTS uma'
  end

  def down
    execute 'DROP SCHEMA IF EXISTS uma'
  end
end
