class CreateUmaSchema < ActiveRecord::Migration[7.0]
  def up
    execute 'CREATE SCHEMA uma'
  end

  def down
    execute 'DROP SCHEMA uma'
  end
end
