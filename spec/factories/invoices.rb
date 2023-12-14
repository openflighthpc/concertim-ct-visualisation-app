require 'faker'

FactoryBot.define do
  factory :invoice, class: 'Invoice' do
    amount { rand(100) }
    balance { rand(100) }
    credit_adj { 0 }
    currency { 'USD' }
    invoice_date { Date.today }
    invoice_id { Faker::Internet.uuid }
    sequence(:invoice_number) { |n| n }
    refund_adj { 0 }
    status { 'COMMITTED' }

    association :account, factory: :user
    items { [] }

    initialize_with { new(attributes) }
  end

  trait :draft do
    status { 'DRAFT' }
  end
end
