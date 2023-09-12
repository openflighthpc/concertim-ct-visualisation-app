FactoryBot.define do
  factory :chassis, class: "Chassis" do
    sequence(:name) { |n| "Chassis-#{n}" }

    association :location
  end
end
