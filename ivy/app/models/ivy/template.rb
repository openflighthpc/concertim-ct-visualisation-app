module Ivy
  class Template < Ivy::Model
    self.primary_key = "template_id"
    self.table_name = "templates"

    #######################
    #
    # Associations
    #
    #######################

    has_many :chassis, class_name: 'Ivy::Chassis'
  end
end
