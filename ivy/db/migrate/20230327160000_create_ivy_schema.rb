class CreateIvySchema < ActiveRecord::Migration[7.0]
  def up
    execute 'CREATE SCHEMA ivy'
  end

  def down
    execute 'DROP SCHEMA ivy'
  end
end
