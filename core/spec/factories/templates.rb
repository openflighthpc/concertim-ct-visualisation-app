FactoryBot.define do
  factory :template, class: 'Template' do
    sequence(:name) { |n| "Template #{n}" }
    depth { 2 }
    description { "" }
    images { {fake: "image"} }
    padding_left { 0 }
    padding_right { 0 }
    padding_top { 0 }
    padding_bottom { 0 }
  end

  trait :rack_template do
    id { HwRack::DEFAULT_TEMPLATE_ID }
    template_type { "HwRack" }
    rackable { "nonrackable" }
    height { 40 }

    after(:create) do
      max_id = Template.pluck(:id).max
      Template.connection.execute <<-SQL
        ALTER SEQUENCE templates_id_seq RESTART WITH #{max_id + 1}
      SQL
    end
  end

  trait :device_template do
    template_type { "Device" }
    rackable { "rackable" }
    rows { 1 }
    columns { 1 }
    height { 1 }
  end
end
