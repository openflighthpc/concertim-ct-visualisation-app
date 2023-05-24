FactoryBot.define do
  factory :rack, class: "Ivy::HwRack" do
    sequence(:name) { |n| "Rack-#{n}" }
    u_height { 1 }
    u_depth { 1 }

    association :user
  end
end
