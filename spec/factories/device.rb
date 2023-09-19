FactoryBot.define do
  factory :device, class: "Device" do
    sequence(:name) { |n| "Device-#{n}" }
    metadata { {openstack_instance: "abc"} }
    status { 'IN_PROGRESS' }

    association :chassis
  end
end
