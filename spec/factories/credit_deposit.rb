FactoryBot.define do
  factory :credit_deposit, class: 'CreditDeposit' do
    amount { rand(1..10) }
    user { create(:user, :with_openstack_details) }
  end

  initialize_with { new(**attributes) }
end
