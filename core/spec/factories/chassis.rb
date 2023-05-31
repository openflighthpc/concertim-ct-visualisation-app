FactoryBot.define do
  factory :chassis, class: "Ivy::Chassis" do
    sequence(:name) { |n| "Chassis-#{n}" }

    association :location
  end
end
