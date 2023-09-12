require 'yaml'

class RackviewPreset < ApplicationRecord

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

