FactoryBot.define do
  factory :device_network_details, class: 'Device::NetworkDetails' do
    admin_state_up { true }
    dns_domain { "moose.net" }
    mtu { 1500 }
    l2_adjacency { true }
    port_security_enabled { false }
    qos_policy { nil }
  end
end
