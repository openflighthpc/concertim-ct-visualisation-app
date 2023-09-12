require 'yaml'

class RackviewPreset < ApplicationRecord
  self.table_name = 'rackview_presets'
  # ensure JSON comes out as {{"ID:1... as opposed to {{"device":{"id:1
  self.include_root_in_json = false

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

