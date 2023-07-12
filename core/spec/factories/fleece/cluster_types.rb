require 'faker'

FactoryBot.define do
  factory :fleece_cluster_type, class: 'Fleece::ClusterType' do
    name { Faker::Tea.variety }
    description { Faker::Quote.yoda }
    foreign_id { Faker::Alphanumeric.alpha }
    version { Time.current }
    fields do
      {
        "clustername"=>
          {
            "type"=>"string",
            "label"=>"Cluster name",
            "order"=>0,
            "constraints"=>
              [
                {
                  "length"=>{"max"=>255, "min"=>6},
                  "description"=>"Cluster name must be between 6 and 255 characters"
                },
                {
                  "description"=>
                  "Cluster name can contain only alphanumeric characters, hyphens and underscores",
                  "allowed_pattern"=>"^[a-zA-Z][a-zA-Z0-9\\-_]*$"
                }
              ],
            "description"=>"The name to give the cluster"
          }
      }
    end
  end
end
