module Ivy
  class DataSource < Ivy::Model

    self.table_name = "data_sources"

    SUPPORTED_DATA_SOURCES=%w( ganglia ) unless defined?(DataSource::SUPPORTED_DATA_SOURCES)

    #ASSOCIATIONS
    belongs_to :cluster
    has_many :datasource_maps


    #VALIDATIONS
    validates :dstype, inclusion: { in: SUPPORTED_DATA_SOURCES }
    validates :ip, :cluster_id, :port, presence: true
    validates :ip, uniqueness: { scope: :port }
    validate  :valid_ip_address?
 

    #HOOKS
    before_save :set_name
    before_validation :strip_attributes


    ########################
    # 
    # Methods
    #
    ########################

    def self::supported_data_sources
      SUPPORTED_DATA_SOURCES
    end

    ########################
    # 
    # Private Methods
    #
    ########################

    private

    def set_name
      self.name="#{self.dstype}://#{self.ip}:#{self.port}"
    end

    def strip_attributes
      ip.strip! if ip.is_a? String
      dstype.strip! if dstype.is_a? String
      default_grid_map.strip! if default_grid_map.is_a? String
      default_cluster_map.strip! if default_cluster_map.is_a? String
      true
    end

    def valid_ip_address?
      begin
        NetAddr::validate_ip_addr(ip)
        return true
      rescue NetAddr::ValidationError, ArgumentError
        errors.add(:ip, "IP address is invalid")
        return false
      end
    end
  end
end
