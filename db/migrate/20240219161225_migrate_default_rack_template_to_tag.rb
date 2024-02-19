class MigrateDefaultRackTemplateToTag < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        # Intentionally not using Template.default_rack_template here!
        rack = Template.find_by(default_rack_template: true)
        rack.tag = 'rack'
        rack.save!
      end

      dir.down do
        rack = Template.find_by_tag('rack')
        rack.default_rack_template = true
        rack.tag = nil
        rack.save!
      end
    end

    # Remove index separately so that db:rollback can recreate it
    remove_index :templates, :default_rack_template, unique: true, where: "default_rack_template = true"
    remove_column :templates, :default_rack_template, :boolean, default: false, null: false
  end
end
