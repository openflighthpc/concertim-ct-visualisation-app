module Meca
  class MecaRange < Meca::Model
    self.table_name = :meca_ranges

    belongs_to :threshold,
      class_name: 'Meca::RangedThreshold'

  end
end
