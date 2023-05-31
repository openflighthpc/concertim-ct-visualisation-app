FactoryBot.define do
  factory :template, class: 'Ivy::Template' do
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
    id { Ivy::HwRack::DEFAULT_TEMPLATE_ID }
    template_type { "HwRack" }
    rackable { "nonrackable" }
    height { 40 }
  end

  trait :device_template do
    template_type { "Device" }
    rackable { "rackable" }
    rows { 1 }
    columns { 1 }
    height { 1 }
  end
end
