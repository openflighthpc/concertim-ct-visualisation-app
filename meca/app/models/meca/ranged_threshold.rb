module Meca
  class RangedThreshold < MecaThreshold
    has_many :ranges, -> { order(:upper_bound) },
      class_name: 'Meca::MecaRange',
      foreign_key: :threshold_id,
      dependent: :destroy
  end
end
