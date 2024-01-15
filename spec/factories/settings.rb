FactoryBot.define do
  factory :setting, class: 'Setting' do
    metric_refresh_interval { 15 }
  end
end
