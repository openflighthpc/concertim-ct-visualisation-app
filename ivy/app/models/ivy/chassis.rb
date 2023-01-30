module Ivy
  class Chassis < Ivy::Model

    self.table_name = "base_chassis"

    #######################
    #
    # Associations
    #
    #######################

    belongs_to  :rack, :class_name => "Ivy::HwRack" 
    belongs_to  :template

    #######################
    #
    # Scopes
    #
    #######################

    scope :rackable_non_showable, -> { where("base_chassis.rack_id is null and base_chassis.show_in_dcrv is not true").joins(:template).where("templates.rackable = ?", 1) }
    scope :dcrvshowable, -> { where("rack_id is null and show_in_dcrv = true") }
  end
end
