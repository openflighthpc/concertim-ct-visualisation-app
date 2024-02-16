class SeedNetworkDeviceTemplate < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|

      dir.up do
        t = Template.new(
          name: 'network',
          template_type: 'Device',
          tag: 'network',
          version: 1,
          height: 1,
          depth: 2,
          rows: 1,
          columns: 1,
          rackable: 'rackable',
          simple: true,
          description: 'Network',
          images: {
            'front' => 'switch_front_1u.png',
            'rear' => 'switch_rear_1u.png',
          }
        )
        t.save!
      end

      dir.down do
        Template.find_by_tag('network')&.destroy!
      end
      
    end
  end
end
