class DevicesCannotBeTagged < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    change_table :devices do |t|
      t.remove :tagged, type: :boolean, default: false, null: false
    end


    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
