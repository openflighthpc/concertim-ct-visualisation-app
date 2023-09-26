class PopulateTemplates < ActiveRecord::Migration[7.0]
  class Template < ActiveRecord::Base
    enum rackable: { rackable: 1, zerouable: 2, nonrackable: 3 }
  end

  def up
    Template.reset_column_information
    templates.each do |t|
      say "Creating template #{t[:name]}"
      template_type = (t[:template_type] || 'Server').to_s
      unless %w[Server HwRack].include?(template_type)
        raise ArgumentError, "Unknown template_type: #{template_type}"
      end
      rackable = template_type == 'Server' ? 'rackable' : 'nonrackable'
      rows = template_type == 'Server' ? 1 : nil
      columns = template_type == 'Server' ? 1 : nil

      record = Template.new(
        id: t[:id],
        name: t[:name],
        height: t[:height],
        depth: t[:depth],
        version: t[:version] || 1,
        template_type: template_type,
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

    # The rack template is created with a specific ID, doing skips the
    # sequence, so we update it here.
    execute <<-SQL
      SELECT setval('templates_id_seq', (SELECT max(id) FROM templates))
    SQL
  end

  def down
    Template.destroy_all
  end

  private

  def templates
    template_dir = Rails.root.join('db/fixtures/chassis_templates/')
    template_dir.glob('*.yaml')
      .map{ |path| [path.basename('.yaml').to_s, YAML.load_file(path)] }
      .map{ |name, data| data.deep_symbolize_keys.reverse_merge(name: name) }
  end
end
