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

class CreateDevice < ActiveRecord::Migration[7.0]
  def change
    create_table :devices do |t|
      t.string :name, limit: 255, null: false
      t.string :description, limit: 255
      t.boolean :hidden, null: false, default: false
      t.integer :modified_timestamp, null: false, default: 0
      t.jsonb :metadata, default: {}, null: false
      t.string :status, null: false
      t.decimal :cost, default: 0.0, null: false
      t.string :public_ips
      t.string :private_ips
      t.string :ssh_key
      t.string :login_user
      t.jsonb :volume_details, default: {}, null: false

      t.timestamps
    end

    add_reference 'devices', 'base_chassis',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :cascade }
  end
end
