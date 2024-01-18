require 'faker'

FactoryBot.define do
  factory :team_role, class: 'TeamRole' do
    role { "member" }

    association :user
    association :team
  end
end
