FactoryBot.define do
  factory :rack, class: "Ivy::HwRack" do
    sequence(:name) { |n| "Rack-#{n}" }
    u_height { 40 }
    u_depth { 2 }
    metadata { {stack_id: "abc123"} }
    status { 'IN_PROGRESS' }

    association :user
  end
end
