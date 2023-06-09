require 'faker'

FactoryBot.define do
  factory :fleece_cluster_type, class: 'Fleece::ClusterType' do
    name { Faker::Tea.variety }
    description { Faker::Quote.yoda }
    kind { Faker::Alphanumeric.alpha }
    nodes { rand(1..100) }
  end
end
