FactoryBot.define do
  factory :rack, class: "Ivy::HwRack" do
    sequence(:name) { |n| "Rack-#{n}" }
    u_height { 40 }
    u_depth { 2 }
    metadata { {} }
    status { 'IN_PROGRESS' }

    association :user
  end
end
