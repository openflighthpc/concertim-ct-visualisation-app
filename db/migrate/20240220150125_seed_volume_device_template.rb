class SeedVolumeDeviceTemplate < ActiveRecord::Migration[7.1]

  class Template < ApplicationRecord
    enum rackable: { rackable: 1, zerouable: 2, nonrackable: 3 }
  end

  def change
    Template.reset_column_information
    reversible do |dir|

      dir.up do
        t = Template.new(
          name: 'volume',
          template_type: 'Device',
          tag: 'volume',
          version: 1,
          height: 2,
          depth: 2,
          rows: 1,
          columns: 1,
          rackable: 'rackable',
          simple: true,
          description: 'Volume',
          images: {
            'front' => 'disk_front_2u.png',
            'rear' => 'generic_rear_2u.png',
          }
        )
        t.save!
      end

      dir.down do
        Template.find_by_tag('volume')&.destroy!
      end
      
    end
  end
end
