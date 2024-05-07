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

class CreateCloudServiceConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :cloud_service_configs do |t|
      t.string :admin_user_id, limit: 255, null: false
      t.string :admin_project_id, limit: 255, null: false
      t.integer :user_handler_port, default: 42356, null: false
      t.integer :cluster_builder_port, default: 42378, null: false
      t.string :host_url, limit: 255, null: false
      t.string :internal_auth_url, limit: 255, null: false
      t.string :admin_foreign_password, limit: 255, null: false

      t.timestamps
    end
  end
end
