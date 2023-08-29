FactoryBot.define do
  factory :key_pair, class: 'Fleece::KeyPair' do
    name { 'keypair' }
    user { create(:user) }
    key_type { "ssh" }
  end
end
