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

class AddLocationModel < ActiveRecord::Migration[7.0]
  def change
    create_table 'locations' do |t|
      t.integer :u_depth, null: false, default: 2
      t.integer :u_height, null: false, default: 1
      t.integer :start_u, null: false
      t.integer :end_u, null: false
      t.string :facing, null: false, default: 'f'

      t.timestamps
    end

    add_reference 'locations', 'rack',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :restrict }

    add_reference 'base_chassis', 'location',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :restrict }
  end
end
