
module Ivy
  class Cluster < Ivy::Model
    self.table_name = "clusters"


    ####################################
    #
    # Associations
    #
    ####################################
    has_many :racks, class_name:"Ivy::HwRack", dependent: :destroy
  end
end
