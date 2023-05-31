FactoryBot.define do
  factory :rack, class: "Ivy::HwRack" do
    sequence(:name) { |n| "Rack-#{n}" }
    u_height { 40 }
    u_depth { 2 }
    metadata { {} }

    association :user
  end
end
