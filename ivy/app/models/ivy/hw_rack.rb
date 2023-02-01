module Ivy
  class HwRack < Ivy::Model

    self.table_name = "racks"

    def self.tagged_device_type; 'RackTaggedDevice'; end

    include Ivy::Concerns::Taggable
    include Ivy::Concerns::Templateable


    #############################
    #
    # CONSTANTS
    # 
    ############################

    SPACE_USED_METRIC_KEY = 'ct.capacity.rack.space_used'


    ############################
    #
    # Associations 
    #
    # Re: chassis relationship (it's done differently here to legacy due to
    # chassis object heirachy having changed). See notes on "rack_chassis"
    # method below.
    #
    ############################
    
    has_many :chassis, ->{ order(:rack_start_u, :desc) },
      class_name: 'Ivy::Chassis',
      foreign_key: :rack_id,
      dependent: :destroy

    has_many :zero_u_rack_chassis, ->{ order(:rack_start_u, :desc) },
      class_name: "Ivy::Chassis::ZeroURackChassis",
      foreign_key: :rack_id,
      dependent: :destroy

    has_many :chassis_rows,           through: :chassis,      source: :chassis_rows
    has_many :slots,                  through: :chassis_rows, source: :slots
    has_many :devices,                through: :slots
    has_many :chassis_tagged_devices, through: :chassis

    has_one :group,
      class_name: "Ivy::Group::RuleBasedGroup",
      foreign_key: :ref_text,
      primary_key: :name

    ####################################
    #
    # Scopes
    #
    ####################################

    scope :excluding_ids,  ->(ids) { where.not(id: ids) }
    scope :modified_after, ->(timestamp) { where("modified_timestamp > ?", timestamp.to_i) }


    ############################
    #
    # Class Methods
    #
    ############################

    def self.get_canvas_config
      JSON.parse(File.read(Engine.root.join("app/views/ivy/racks/_configuration.json")))
    end


    ####################################
    #
    # Instance Methods
    #
    ####################################

    #
    # number_of_devices
    #
    def number_of_devices
      group ? (MEMCACHE.get("hacor:group:#{group.id}")[:members].size rescue 0) : 0
    end

    #
    # space_used
    #
    def space_used
      value_for_metric(SPACE_USED_METRIC_KEY).to_i rescue 0
    end

    #
    # total_space
    # 
    def total_space
      u_height
    end
  
  end
end
