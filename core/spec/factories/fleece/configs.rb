FactoryBot.define do
  factory :fleece_config, class: 'Fleece::Config' do
    host_name { Faker::Internet.domain_name }
    host_ip { IPAddr.new(Faker::Internet.ip_v4_address) }
    username { Faker::Internet.username }
    password { Faker::Internet.password }
    port { rand(1...65535) }
    user_handler_port { rand(1...65535) }
    project_name { "project-#{Faker::Alphanumeric.alphanumeric}" }
    domain_name { Faker::Internet.domain_name }
  end
end
