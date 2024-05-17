FactoryBot.define do
  factory :network, class: "Network" do
    sequence(:name) { |n| "Network-#{n}" }
    metadata { {openstack_instance: "abc"} }
    status { 'IN_PROGRESS' }
    type { "Network" }

    association :chassis
    association :details, factory: :device_network_details
  end
end
