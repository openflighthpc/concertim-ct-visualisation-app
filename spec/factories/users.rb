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
  factory :user, class: 'User' do
    sequence(:login) { |n| "user-#{n}" }
    sequence(:name) { |n| "User #{n}" }
    email { "#{login}@example.com" }
    cloud_user_id { nil }
    root { false }

    password { SecureRandom.alphanumeric }
  end

  trait :with_openstack_account do
    cloud_user_id { Faker::Alphanumeric.alphanumeric(number: 10) }
  end

  trait :admin do
    sequence(:login) { |n| "admin-#{n}" }
    sequence(:name) { |n| "Admin #{n}" }
    root { true }
  end

  trait :member_of_empty_rack do
    after(:create) do |user, context|
      rack_template = Template.default_rack_template
      if rack_template.nil?
        rack_template = create(:template, :rack_template)
      end
      rack = create(:rack, template: rack_template)
      create(:team_role, team: rack.team, user: user)
    end
  end

  trait :with_team_role do
    transient do
      role { 'member' }
      team { create(:team) }
    end

    after(:create) do |user, evaluator|
      user.team_roles.create!(role: evaluator.role, team: evaluator.team)
    end
  end

  trait :as_team_member do
    with_team_role
    role { 'member' }
  end

  trait :as_team_admin do
    with_team_role
    role { 'admin' }
  end
end
