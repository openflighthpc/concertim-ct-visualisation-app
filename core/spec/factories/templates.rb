FactoryBot.define do
  factory :template, class: 'Ivy::Template' do
    sequence(:name) { |n| "Template #{n}" }
    height { 1 }
    depth { 1 }
    description { "" }
    images { {fake: "image"} }
    padding_left { 0 }
    padding_right { 0 }
    padding_top { 0 }
    padding_bottom { 0 }
  end

  trait :rack_template do
    template_type { "HwRack" }
    rackable { "nonrackable" }
  end
end
