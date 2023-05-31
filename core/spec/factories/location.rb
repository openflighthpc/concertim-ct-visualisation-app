FactoryBot.define do
  factory :location, class: "Ivy::Location" do
    u_height { 1 }
    u_depth { 2 }
    start_u { 1 }
    facing { 'f' }

    association :rack
  end
end
