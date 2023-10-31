require 'faker'

FactoryBot.define do
  factory :cloud_service_config, class: 'CloudServiceConfig' do
    internal_auth_url { "http://#{Faker::Internet.domain_name}:5000" }
    admin_user_id { Faker::Internet.username }
    admin_foreign_password { Faker::Internet.password }
    user_handler_base_url { "http://#{Faker::Internet.domain_name}:42356" }
    cluster_builder_base_url { "http://#{Faker::Internet.domain_name}:42378" }
    admin_project_id { "project-#{Faker::Alphanumeric.alphanumeric}" }
  end
end
