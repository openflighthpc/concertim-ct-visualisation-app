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

class AddDefaultTemplateToTemplate < ActiveRecord::Migration[7.0]
  class Template < ActiveRecord::Base; end

  def change
    add_column :templates, :default_rack_template, :boolean, default: false, null: false
    add_index :templates, :default_rack_template, unique: true, where: "default_rack_template = true"

    reversible do |dir|
      dir.up do
        default_template_id = 1
        Template.reset_column_information
        default_rack_template = Template.find_by_id(default_template_id)
        unless default_rack_template.nil?
          default_rack_template.update(default_rack_template: true)
        end
      end
      dir.down do
        # Nothing to do here as we're about to delete the default_template column.
        Template.reset_column_information
      end
    end
  end
end
