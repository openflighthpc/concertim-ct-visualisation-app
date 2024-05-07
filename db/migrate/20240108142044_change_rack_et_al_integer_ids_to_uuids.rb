#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

# Migrate the template, rack, location, chassis and device tables to use a uuid
# primary key instead of a sequential integer primary key.
#
# There are a number of foreign keys that need to be respected during this
# migration.  To do that properly we would need to (1) add a uuid key to the
# tables and populate; (2) add a new foreign key column and populate it
# correctly; (3) potentially, migrate the directory structure for any persisted
# metrics to match the new primary key for the devices; (4) remove the old
# primary keys and foreign keys.
#
# That is quite involved and I'd like to avoid that complexity.  The data
# migration can be simplified by deleting all of the racks, devices, etc and
# rely on the middleware to repopulate them.  This results in the loss of any
# historical metrics, but as we have not yet had a production release this is
# acceptable.
class ChangeRackEtAlIntegerIdsToUuids < ActiveRecord::Migration[7.0]
  class Template < ActiveRecord::Base
  end
  class HwRack < ActiveRecord::Base
    self.table_name = "racks"
    has_many :locations, ->{ order(start_u: :desc) }, foreign_key: :rack_id, dependent: :destroy
  end
  class Location < ActiveRecord::Base
    belongs_to :rack, :class_name => "HwRack"
    has_one :chassis, dependent: :destroy
  end
  class Chassis < ActiveRecord::Base
    self.table_name = "base_chassis"
    belongs_to :location, dependent: :destroy
    has_one :device, foreign_key: :base_chassis_id, dependent: :destroy
  end
  class Device < ActiveRecord::Base
    has_one :data_source_map, dependent: :destroy
    belongs_to :chassis, foreign_key: :base_chassis_id
  end
  class DataSourceMap < ActiveRecord::Base
    belongs_to :device
  end

  def up
    HwRack.reset_column_information
    Location.reset_column_information
    Chassis.reset_column_information
    Device.reset_column_information
    DataSourceMap.reset_column_information

    # Remove all templates, racks, devices, etc rows.
    HwRack.destroy_all
    Template.where.not(default_rack_template: true).destroy_all

    # Remove all of the relevant foreign keys columns.
    remove_reference 'locations', 'rack'
    remove_reference 'base_chassis', 'location'
    remove_reference 'devices', 'base_chassis'
    remove_reference 'data_source_maps', 'device'
    remove_reference 'base_chassis', 'template'
    remove_reference 'racks', 'template'

    # Add new UUID primary keys and remove old integer primary keys.
    %w(
      racks
      locations
      base_chassis
      devices
      data_source_maps
      templates
    ).each do |table|
      add_column table, :uuid, :uuid, default: "gen_random_uuid()", null: false
      change_table table do |t|
        t.remove :id
        t.rename :uuid, :id
      end
      execute "ALTER TABLE #{table} ADD PRIMARY KEY (id);" 
    end

    # Add back the removed foreign key columns.
    add_reference 'locations', 'rack', null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }, type: :uuid
    add_reference 'base_chassis', 'location', null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }, type: :uuid
    add_reference 'devices', 'base_chassis', null: false, foreign_key: { on_update: :cascade, on_delete: :cascade }, type: :uuid
    add_reference 'data_source_maps', 'device', null: false, foreign_key: { on_update: :cascade, on_delete: :cascade }, type: :uuid
    add_reference 'base_chassis', 'template', null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }, type: :uuid
    add_reference 'racks', 'template', null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }, type: :uuid
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
