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

require 'faker'

FactoryBot.define do
  factory :cluster_type, class: 'ClusterType' do
    name { Faker::Tea.variety }
    description { Faker::Quote.yoda }
    foreign_id { Faker::Alphanumeric.alpha }
    version { Time.current }
    fields do
      {
        "clustername"=>
          {
            "type"=>"string",
            "label"=>"Cluster name",
            "order"=>0,
            "constraints"=>
              [
                {
                  "length"=>{"max"=>255, "min"=>6},
                  "description"=>"Cluster name must be between 6 and 255 characters"
                },
                {
                  "description"=>
                  "Cluster name can contain only alphanumeric characters, hyphens and underscores",
                  "allowed_pattern"=>"^[a-zA-Z][a-zA-Z0-9\\-_]*$"
                }
              ],
            "description"=>"The name to give the cluster"
          }
      }
    end
  end
end
