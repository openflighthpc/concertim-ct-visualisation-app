FactoryBot.define do
  factory :user, class: 'Uma::User' do
    sequence(:login) { |n| "user-#{n}" }
    sequence(:name) { |n| "User #{n}" }
    email { "#{login}@example.com" }
    project_id { nil }
    root { false }

    password { SecureRandom.alphanumeric }
  end

  trait :admin do
    sequence(:login) { |n| "admin-#{n}" }
    sequence(:name) { |n| "Admin #{n}" }
    root { true }
  end
end
