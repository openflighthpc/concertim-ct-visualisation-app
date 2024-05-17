FactoryBot.define do
  factory :volume, class: "Volume" do
    sequence(:name) { |n| "Volume-#{n}" }
    metadata { {openstack_instance: "abc"} }
    status { 'IN_PROGRESS' }
    type { "Volume" }

    association :chassis
    association :details, factory: :device_volume_details
  end
end
