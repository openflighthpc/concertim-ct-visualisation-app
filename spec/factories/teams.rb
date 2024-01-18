require 'faker'

FactoryBot.define do
  factory :team, class: 'Team' do
    sequence(:name) { |n| "Team #{n}" }
    project_id { nil }
    billing_acct_id { nil }
  end

  trait :with_openstack_details do
    project_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    billing_acct_id { Faker::Alphanumeric.alphanumeric(number: 10) }
  end

  trait :with_empty_rack do
    after(:create) do |team, context|
      rack_template = Template.default_rack_template
      if rack_template.nil?
        rack_template = create(:template, :rack_template)
      end
      create(:rack, team: team, template: rack_template)
    end
  end
end
