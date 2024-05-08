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

class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string :name, limit: 255, null: false
      t.string :project_id, limit: 255
      t.string :billing_acct_id, limit: 255
      t.decimal :cost, default: 0.00, null: false
      t.decimal :credits, default: 0.00, null: false
      t.date :billing_period_start
      t.date :billing_period_end
      t.datetime :deleted_at

      t.timestamps
    end

    add_index  :teams, :billing_acct_id, unique: true, where: "NOT NULL"
    add_index :teams, :project_id, unique: true, where: "NOT NULL"
    add_index :teams, :deleted_at,
              where: 'deleted_at IS NOT NULL',
              name: 'teams_deleted_at_not_null'
    add_index :teams, :deleted_at,
              where: 'deleted_at IS NULL',
              name: 'teams_deleted_at_null'
  end
end
