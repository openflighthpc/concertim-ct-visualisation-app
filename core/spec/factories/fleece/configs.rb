FactoryBot.define do
  factory :fleece_config, class: 'Fleece::Config' do
    host_name { "hostname" }
    host_ip { IPAddr.new("8.8.8.8") }
    username { "username" }
    password { "password" }
    port { 1 }
    project_name { "project-name" }
    domain_name { "domain-name" }
  end
end
