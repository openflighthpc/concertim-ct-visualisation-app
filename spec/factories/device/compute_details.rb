FactoryBot.define do
  factory :device_compute_details, class: 'Device::ComputeDetails' do
    public_ips { "somenet:192.168.1.100" }
    private_ips { "someothernet:10.10.100.101" }
    ssh_key { "" }
    login_user { "" }
  end
end
