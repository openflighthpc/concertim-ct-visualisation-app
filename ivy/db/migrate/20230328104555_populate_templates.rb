class PopulateTemplates < ActiveRecord::Migration[7.0]
  class Template < ActiveRecord::Base
    establish_connection :ivy
  end

  def up
    templates.each do |t|
      chassis_type = (t[:chassis_type] || 'Server').to_s
      unless %w[Server HwRack].include?(chassis_type)
        raise ArgumentError, "Unknown chassis_type: #{chassis_type}"
      end
      rackable = chassis_type == 'Server' ? 1 : 3
      rows = chassis_type == 'Server' ? 1 : nil
      columns = chassis_type == 'Server' ? 1 : nil

      record = Template.new(
        id: t[:id],
        name: t[:name],
        height: t[:height],
        depth: t[:depth],
        version: t[:version] || 1,
        chassis_type: chassis_type,
        rackable: rackable,
        simple: true,
        description: t[:description],
        images: t[:images],
        rows: rows,
        columns: columns,

        model: t[:model],
        rack_repeat_ratio: t[:rack_repeat_ratio],
      )

      if t.has_key?(:padding)
        record.padding_left = t[:padding][:left]
        record.padding_bottom = t[:padding][:bottom]
        record.padding_right = t[:padding][:right]
        record.padding_top = t[:padding][:top]
      end

      record.save!
    end
  end

  def down
    Template.destroy_all
  end

  private

  def templates
    template_dir = ::Ivy::Engine.root.join('db/fixtures/chassis_templates/')
    template_dir.glob('*.yaml')
      .map{ |path| [path.basename('.yaml').to_s, YAML.load_file(path)] }
      .map{ |name, data| data.deep_symbolize_keys.reverse_merge(name: name) }
  end
end
