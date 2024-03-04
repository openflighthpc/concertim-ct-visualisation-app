FactoryBot.define do
  factory :cluster, class: 'Cluster' do
    name { 'mycluster' }
    cluster_type { create(:cluster_type) }
    team { create(:team, :with_openstack_details, credits: 1000) }

    initialize_with { new(**attributes) }
  end
end
