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
