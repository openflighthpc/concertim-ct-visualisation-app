# DataSourceMap allows for configuring how to find metrics for a device.  A map
# to the source of metric data if you will.
#
# Concertim uses ganglia to process it metrics.  Once ganglia has processed
# them the metrics are available in a particular "grid", "cluster" and "host".
# Here "grid", "cluster" and "host" are ganglia specific terms.
#
# If a device has a data source map of say, `{map_to_grid: "unspecified", map_to_cluster: "unspecified", map_to_host: "my-device"}`
# then to find its output in the ganglia stream of metrics would involve
# searching the grid with the name "unspecified", searching within that grid
# for the cluster with the name "unspecified" and searching within that cluster
# for the host with the name "my-device".
#
class DataSourceMap < ApplicationRecord

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
    "#{device.class.name.demodulize.downcase}:#{device.id}"
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
