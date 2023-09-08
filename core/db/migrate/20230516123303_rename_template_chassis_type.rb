class RenameTemplateChassisType < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    change_table :templates do |t|
      t.rename :chassis_type, :template_type
    end

    reversible do |dir|
      dir.up {
        execute "UPDATE templates SET template_type = 'Device' where template_type = 'Server'"
      }
      dir.down {
        execute "UPDATE templates SET template_type = 'Server' where template_type = 'Device'"
      }
    end

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
