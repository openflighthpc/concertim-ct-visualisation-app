class DataSourceMap < ApplicationRecord

  include DataSourceMap::Interchange

  ######################################
  #
  # Validations
  #
  ######################################

  validates :map_to_host,
            presence: true,
            uniqueness: true,
            length: { maximum: 150, allow_blank: false, message: "Data source host reference cannot be greater than 150 characters" }
  validates :device_id, presence: true


  ######################################
  #
  # Associations
  #
  ######################################

  belongs_to :device


  ######################################
  #
  # Defaults
  #
  ######################################

  def set_defaults
    self.map_to_grid ||= 'unspecified'
    self.map_to_cluster ||= 'unspecified'
    self.map_to_host     ||= calculate_map_to_host
  end


  ######################################
  #
  # Hooks
  #
  ######################################
  after_initialize :set_defaults, if: Proc.new {|r| r.new_record? }
  before_validation :strip_attributes, :assign_map_to_host

  # before_update :update_metrics
  # after_save :update_interchange
  # after_destroy :remove_from_interchange
  # after_initialize :set_original_values



  ######################################
  #
  # Instance Methods
  #
  ######################################

  def strip_attributes
    #MMM Could this method be private?
    map_to_grid.strip! if map_to_grid.is_a? String
    map_to_cluster.strip! if map_to_cluster.is_a? String
    map_to_host.strip! if map_to_host.is_a? String
    true
  end


  def calculate_map_to_host
    if device.respond_to?(:generate_dsm)
      device.generate_dsm
    else
      "#{device.class.name.demodulize.downcase}:#{device.id}"
    end
  end


  ######################################
  #
  # Private Instance Methods
  #
  ######################################

  private

  def assign_map_to_host
    if map_to_host.nil? || map_to_host.strip.empty?
      self.map_to_host = calculate_map_to_host
    end
  end
end
