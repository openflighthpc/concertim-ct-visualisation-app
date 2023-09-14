require 'faker'

FactoryBot.define do
  factory :user, class: 'User' do
    sequence(:login) { |n| "user-#{n}" }
    sequence(:name) { |n| "User #{n}" }
    email { "#{login}@example.com" }
    project_id { nil }
    cloud_user_id { nil }
    root { false }

    password { SecureRandom.alphanumeric }
  end

  trait :with_openstack_details do
    project_id { Faker::Internet.uuid.gsub(/-/, '') }
    cloud_user_id { Faker::Internet.uuid }
  end

  trait :admin do
    sequence(:login) { |n| "admin-#{n}" }
    sequence(:name) { |n| "Admin #{n}" }
    root { true }
  end
end
