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
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

class CreateTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table 'templates' do |t|
      t.string :name, limit: 255, null: false, default: ''
      t.integer :height, null: false
      t.integer :depth, null: false
      t.integer :version, null: false, default: 1
      t.string :template_type, limit: 255, null: false
      t.integer :rackable, null: false, default: 1
      t.boolean :simple, null: false, default: true
      t.string :description, limit: 255
      t.jsonb :images, null: false, default: {}
      t.integer :rows
      t.integer :columns
      t.integer :padding_left, null: false, default: 0
      t.integer :padding_bottom, null: false, default: 0
      t.integer :padding_right, null: false, default: 0
      t.integer :padding_top, null: false, default: 0
      t.string :foreign_id
      t.integer :vcpus
      t.integer :ram
      t.integer :disk

      # Needed for IRV structure.  Should be removed eventually.
      t.string :model, limit: 255
      t.string :rack_repeat_ratio, limit: 255

      t.timestamps
    end
  end
end
