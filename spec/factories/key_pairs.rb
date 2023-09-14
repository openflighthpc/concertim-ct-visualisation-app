FactoryBot.define do
  factory :key_pair, class: 'KeyPair' do
    name { 'keypair' }
    user { create(:user) }
    key_type { "ssh" }
  end

  initialize_with { new(**attributes) }
end
