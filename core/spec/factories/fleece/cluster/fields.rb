FactoryBot.define do
  factory :fleece_cluster_field, class: 'Fleece::Cluster::Field' do
    id { 'cluster_name' }
    details do
      {
        "type"=>"string",
        "order"=>0,
        "default"=>"mylovelycluster",
        "description"=>"What your cluster is called."
      }
    end

    initialize_with { new(id, details) }
  end
end
