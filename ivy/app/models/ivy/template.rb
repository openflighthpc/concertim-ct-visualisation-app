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


    ####################################
    #
    # Scopes
    #
    ####################################

    # Templates that can be located in a rack.
    scope :rackables, -> { where("rackable =  ?",1) }


    #######################
    #
    # Instance Methods
    #
    #######################

    def complex?
      !simple?
    end
  end
end
