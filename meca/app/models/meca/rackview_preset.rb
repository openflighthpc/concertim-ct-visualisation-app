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

  end
end

