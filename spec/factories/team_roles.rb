require 'faker'

FactoryBot.define do
  factory :team_role, class: 'TeamRole' do
    role { "member" }

    association :user,:with_openstack_account
    association :team
  end
end
