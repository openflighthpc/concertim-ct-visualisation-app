require 'yaml'

module Meca
  class RackviewPreset < ApplicationRecord

    self.table_name = 'rackview_presets'

    ############################
    #
    # Associations
    #
    ############################

    belongs_to :user, class_name: 'User'


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

