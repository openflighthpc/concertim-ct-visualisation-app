#
# Meca::MecaThreshold
#
# This class has issues:
#
# * Long methods
# * Weird code / confusing methods.
# * Presentation logic within the model. 
#
module Meca
  class MecaThreshold < Meca::Model
    self.table_name = "meca_thresholds"

    def simple?
      self.class == Meca::SimpleThreshold
    end

    def ranged?
      self.class == Meca::RangedThreshold
    end

  end
end
