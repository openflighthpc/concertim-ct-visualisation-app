class RemoveDeviceSubclasses < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    change_table :devices do |t|
      t.remove :type, type: :string, limit: 255, null: false, default: 'Server'
    end

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
