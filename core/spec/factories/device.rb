FactoryBot.define do
  factory :device, class: "Ivy::Device" do
    sequence(:name) { |n| "Device-#{n}" }
    metadata { {} }

    association :chassis
  end
end
