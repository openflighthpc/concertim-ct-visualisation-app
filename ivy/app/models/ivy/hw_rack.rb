module Ivy
  class HwRack < Ivy::Model

    self.table_name = "racks"

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

  end
end
