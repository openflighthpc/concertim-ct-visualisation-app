require 'yaml'

module Meca
  class RackviewPreset < ApplicationRecord

    self.table_name = 'rackview_presets'


    ####################################
    #
    # Validations
    #
    ####################################

    validates :name, presence: true
    validates :default, inclusion: [true, false]
    validates :values, presence: true


    ####################################
    #
    # Instance Methods
    #
    ####################################

    def values=(v)
      super(YAML.dump(v))
    end

    def values
      YAML.load(super)
    rescue
      {}
    end

  end
end

