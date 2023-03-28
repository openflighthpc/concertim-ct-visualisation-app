
module Ivy
  class Cluster < ApplicationRecord
    self.table_name = "clusters"


    ####################################
    #
    # Associations
    #
    ####################################
    has_many :racks, class_name:"Ivy::HwRack", dependent: :destroy
  end
end
