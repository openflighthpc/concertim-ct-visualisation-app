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

    DEFAULT_TEMPLATE_ID = 669
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
    
    has_many :chassis, ->{ order(rack_start_u: :desc) },
      class_name: 'Ivy::Chassis',
      foreign_key: :rack_id,
      dependent: :destroy

    has_many :zero_u_rack_chassis, ->{ order(rack_start_u: :desc) },
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

    ############################
    #
    # Validations 
    #
    ############################

    validates :name, presence: true, uniqueness: { scope: :cluster_id }
    validates :cluster_id, presence: true
    validates :u_depth, numericality: { only_integer: true, greater_than: 0 }
    validates :u_height, numericality: { only_integer: true, greater_than: 0, less_than: 73 }
    validate :u_height_greater_than_highest_occupied_u?, unless: :new_record?
    validate :rack_limit, if: :new_record?

    # 
    # u_height is not allowed to be lower than space used. 
    #
    def u_height_greater_than_highest_occupied_u?
      if !(u_height >= highest_empty_u)
        self.errors.add(:u_height, "must be greater than the highest occupied slot (minimum is therefore #{highest_empty_u}).")
      end
    end

    def rack_limit 
      limit = YAML.load_file("/etc/concurrent-thinking/appliance/release.yml")['rack_limit'] rescue nil 
      return if limit.nil? || Ivy::HwRack.count < limit 
      self.errors.add(:base, "The rack limit of #{limit} has been exceeded") 
    end 

    ############################
    #
    # Defaults 
    #
    ############################

    def set_defaults
      last_rack = ( cluster || Ivy::Cluster.first ).racks.last rescue nil
      self.u_depth ||= 2
      if last_rack
        self.template_id ||= DEFAULT_TEMPLATE_ID
        self.u_height ||= last_rack.nil? ? 42 : last_rack.u_height
      end
      self.name ||=
        if last_rack
          last_rack.name.sub(/(\d+)(\D*$)/) do |m|
            sprintf("%0#{$1.length}d%s", $1.to_i + 1, $2)
          end
        else
          "Rack-#{Ivy::HwRack.count + 1}"
        end        
    end


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

    # XXX Do we still want this?
    #
    # Currently it's only here so that we can make sure that the device
    # representing the MIA isn't deleted as part of a rack deletion.
    #
    # Perhaps it would be best to just not have a device representing a MIA;
    # have someother mechanism to handle this.
    Ivy::Device::ManagedDevice::MANAGEMENT_APPLIANCE_TYPES.each do |type|
      type = type.to_s
      define_method(type) do
        iv = instance_variable_get("@#{type.pluralize}")
        if iv.nil?
          instance_variable_set(
            "@#{type.pluralize}", 
            Ivy::Device::ManagedDevice
              .joins(device_joins)
              .where(['base_chassis.rack_id = ? and role = ?', id, type])
              .order('"devices"."index"')
              .first
          )
        else
          iv
        end
      end
    end


    ####################################
    #
    # Instance Methods
    #
    ####################################

    def empty?
      devices.empty? && chassis_tagged_devices.empty?
    end

    #
    # number_of_devices
    #
    def number_of_devices
      group ? (MEMCACHE.get("hacor:group:#{group.id}")[:members].size rescue 0) : 0
    end

    # Return the highest empty u for the given facing.
    # Half empty u will be included iff they are empty in the given facing.
    def highest_empty_u(facing = nil)
      if facing.nil?
        return (chassis.select{|ch| ch.type != 'ZeroURackChassis'}.map(&:rack_end_u).compact.sort.last || 0)
      else
        height = (u_height.nil? || u_height.blank?) ? 1 : u_height 
        return first_empty_u( ( 1..height ).to_a.reverse, facing)
      end
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

    def contains_mia?
      !mia.nil?
    end

    ############################
    #
    # Private Instance Methods
    #
    ############################

    private

    def device_joins
      {:slot => {:chassis_row => :chassis}}
    end

  end
end
