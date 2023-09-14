FactoryBot.define do
  factory :cluster, class: 'Cluster' do
    name { 'mycluster' }
    cluster_type { create(:cluster_type) }

    initialize_with { new(**attributes) }
  end
end
