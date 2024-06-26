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
