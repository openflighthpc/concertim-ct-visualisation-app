require 'faker'

FactoryBot.define do
  factory :fleece_cluster, class: 'Fleece::Cluster' do
    name { 'mycluster' }
    cluster_type { create(:fleece_cluster_type) }

    initialize_with { new(**attributes) }
  end
end
