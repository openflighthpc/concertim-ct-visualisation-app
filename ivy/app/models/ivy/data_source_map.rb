module Ivy
  class DataSourceMap < Ivy::Model

    self.table_name = "data_source_maps"

    ######################################
    #
    # Validations 
    #
    ######################################

    validates :map_to_host, uniqueness: { scope: :data_source_id, message: ' should be one per data_source_id'}
    validates :data_source_id, :map_to_host, :device_id, presence: true
    validates :map_to_host, length: { maximum: 150, allow_blank: false, message: "Data source host reference cannot be greater than 150 characters" }


    ######################################
    #
    # Associations 
    #
    ######################################

    belongs_to :data_source
    belongs_to :device


    ######################################
    #
    # Defaults 
    #
    ######################################

    def set_defaults
      #MMM defensive code added during migration
      if default_data_source
        self.map_to_grid     ||= default_data_source.default_grid_map   
        self.map_to_cluster  ||= default_data_source.default_cluster_map
        self.data_source_id  ||= default_data_source.id     
      end
      self.map_to_host     ||= calculate_map_to_host
    end


    ######################################
    #
    # Hooks 
    #
    ######################################

    before_validation :strip_attributes, :assign_map_to_host
    # before_update :update_metrics
    # after_save :update_power_strip_interchange, :update_interchange
    # after_destroy :update_power_strip_interchange, :remove_from_interchange
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
      elsif device.name.blank?        
        ".#{device.cluster.domain}".tr(' ','-')
      else        
        "#{device.name}.#{device.cluster.domain}".tr(' ','-')
      end      
    end


    ######################################
    #
    # Private Instance Methods
    #
    ######################################

    private

    def default_data_source
      Ivy::DataSource.first
      # if device.nil?
      #   Ivy::DataSource.first
      # else
      #   device.available_data_sources.first       
      # end
    end

    def assign_map_to_host   
      if map_to_host.nil? || map_to_host.strip.empty?      
        self.map_to_host = calculate_map_to_host        
      end      
    end
  end
end
