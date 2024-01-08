class AddDefaultTemplateToTemplate < ActiveRecord::Migration[7.0]
  class Template < ActiveRecord::Base; end

  def change
    add_column :templates, :default_rack_template, :boolean, default: false, null: false
    add_index :templates, :default_rack_template, unique: true, where: "default_rack_template = true"

    reversible do |dir|
      dir.up do
        default_template_id = 1
        Template.reset_column_information
        default_rack_template = Template.find_by_id(default_template_id)
        unless default_rack_template.nil?
          default_rack_template.update(default_rack_template: true)
        end
      end
      dir.down do
        # Nothing to do here as we're about to delete the default_template column.
        Template.reset_column_information
      end
    end
  end
end
