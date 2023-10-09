require 'faker'

FactoryBot.define do
  factory :user, class: 'User' do
    sequence(:login) { |n| "user-#{n}" }
    sequence(:name) { |n| "User #{n}" }
    email { "#{login}@example.com" }
    project_id { nil }
    cloud_user_id { nil }
    billing_acct_id { nil }
    root { false }

    password { SecureRandom.alphanumeric }
  end

  trait :with_openstack_details do
    project_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    cloud_user_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    billing_acct_id { Faker::Alphanumeric.alphanumeric(number: 10) }
  end

  trait :admin do
    sequence(:login) { |n| "admin-#{n}" }
    sequence(:name) { |n| "Admin #{n}" }
    root { true }
  end
end
