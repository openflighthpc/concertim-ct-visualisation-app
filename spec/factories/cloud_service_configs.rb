require 'faker'

FactoryBot.define do
  factory :cloud_service_config, class: 'CloudServiceConfig' do
    host_url { "http://#{Faker::Internet.domain_name}:5000" }
    internal_auth_url { "http://#{Faker::Internet.domain_name}:5000" }
    admin_user_id { Faker::Internet.username }
    admin_foreign_password { Faker::Internet.password }
    user_handler_port { rand(1...65535) }
    cluster_builder_port { rand(1...65535) }
    admin_project_id { "project-#{Faker::Alphanumeric.alphanumeric}" }
  end
end
