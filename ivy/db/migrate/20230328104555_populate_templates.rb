class PopulateTemplates < ActiveRecord::Migration[7.0]
  class Template < ActiveRecord::Base
    establish_connection :ivy
  end

  def up
    templates.each do |t|
      record = Template.new(
        id: t[:id],
        template_id: t[:id],
        template_name: t[:template_name],
        height: t[:height],
        depth: t[:depth],
        version: t[:version] || 1,
        chassis_type: t[:device].has_key?(:type) ? t[:device][:type] : 'Server',
        rackable: t[:rackable] || 1,
        simple: true,
        description: t[:device][:description],
        images: t.has_key?(:metadata) ? t[:metadata][:images] : nil,
        rows: 1,
        columns: 1,

        name: t[:template_name],
        manufacturer: t[:device][:manufacturer],
        model: t[:device][:model],
        product_url: t[:product_url],
        rack_repeat_ratio: t.has_key?(:metadata) ? t[:metadata][:rack_repeat_ratio] : nil,
      )

      if t.has_key?(:metadata) && t[:metadata][:padding]
        record.padding_left = t[:metadata][:padding][:left]
        record.padding_bottom = t[:metadata][:padding][:bottom]
        record.padding_right = t[:metadata][:padding][:right]
        record.padding_top = t[:metadata][:padding][:top]
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
      .map{ |name, data| data.deep_symbolize_keys.reverse_merge(template_name: name) }
  end
end
