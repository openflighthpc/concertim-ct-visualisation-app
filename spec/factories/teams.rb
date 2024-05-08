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
  factory :team, class: 'Team' do
    sequence(:name) { |n| "Team #{n}" }
    project_id { nil }
    billing_acct_id { nil }
  end

  trait :with_openstack_details do
    project_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    billing_acct_id { Faker::Alphanumeric.alphanumeric(number: 10) }
  end

  trait :with_empty_rack do
    after(:create) do |team, context|
      rack_template = Template.default_rack_template
      if rack_template.nil?
        rack_template = create(:template, :rack_template)
      end
      create(:rack, team: team, template: rack_template)
    end
  end
end
