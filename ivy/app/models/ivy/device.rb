module Ivy
  class Device < Ivy::Model
    self.table_name = "devices"

    include Ivy::Concerns::Interchange

    # The next 2 attributes are copied across from new-legacy.  They were used
    # there to allow the user to change the template (associated to the
    # chassis) on the device creation form.
    # This would be much better done with the introduction of form objects
    # instead.
    attr_accessor :template_manufacturer
    attr_accessor :template_id


    ####################################
    #
    # Associations
    #
    ####################################

    belongs_to :slot, optional: true
    has_one :chassis_row, through: :slot, class_name: 'Ivy::ChassisRow'
    has_one :data_source_map, dependent: :destroy 

    #
    # A device can have a relationship with a chassis in one of two ways:
    #
    # * A direct relationship, where base_chassis_id on devices joins straight
    #   to the base_chassis table
    # * An indirect relationship, through slots => chassis_rows => base_chassis
    #
    # A direct relationship indicates that the device is a "tagged" device -
    # unfortunately doing things this way means the relationship between a
    # device and a chassis can't be implemented in a simple way. Instead, we
    # have two relationships (one for each of the two bullet points above) and
    # a convinience method within the device class called "chassis" that works
    # out which to call.
    #
    belongs_to :direct_chassis, class_name:  "Ivy::Chassis", foreign_key: :base_chassis_id, optional: true
    has_one :indirect_chassis, through: :chassis_row, class_name: "Ivy::Chassis"

    #
    # similar technique to chassis has been applied to the rack relationship, as this is
    # based on the rack relationship.
    #
    has_one :direct_rack, through: :direct_chassis, source: :rack
    has_one :indirect_rack, through: :indirect_chassis, source: :rack

    # We probably don't need this association.  It's currently used by the `blank` scope.
    has_one :template, through: :indirect_chassis, source: :template

    #
    # As per above, we now have direct and indirect "templates" through the
    # respective chassis.
    # 
    has_one :indirect_template, through: :indirect_chassis, source: :template
    has_one :direct_template, through: :direct_chassis, source: :template


    ###########################
    #
    # Validations
    #
    ###########################

    validates :name, presence: true, length: { maximum: 150 }
    validates :slot_id, uniqueness: true, allow_nil: true
    validates :slot_id, presence: true, unless: ->{ is_a?(Sensor) || tagged? }
    validate :name_validator
    validate :device_limit, if: :new_record? 

    #############################
    #
    # Scopes 
    #
    #############################

    scope :tagged,           ->{ where("devices.tagged = ?", true) } 
    scope :untagged,         ->{ where("devices.tagged != ?", true) } 
    scope :blank,            ->{ joins(:template).where("templates.model LIKE '%Blank Panel%'") }
    scope :occupying_rack_u, ->{ joins(:indirect_rack).where(base_chassis: {type: :RackChassis}) }

    ####################################
    #
    # Delegation 
    #
    ####################################

    delegate :manufacturer, :model,
      to: :template, allow_nil: true

    delegate :simple?, :complex?,
      to: :chassis, allow_nil: true, prefix: true

    ###########################
    #
    # Hooks
    #
    ###########################

    after_save :create_or_update_data_source_map
    # XXX Probably want to also port
    # :update_modified_timestamp / :update_rack_modified_timestamp
    # :remove_metrics
    # :destroy_breaches

    ####################################
    #
    # Class Methods
    #
    ####################################

    def self.types
      @types ||= [Ivy::Device]
    end

    # def self.inherited(sub_class)
    #   Ivy::Slot.create_association_for(sub_class)
    #   super
    # end

    ####################################
    #
    # Instance Methods
    #
    ####################################
    
    # 
    # has_direct_chassis
    #
    # Some devices (tagged ones) have a direct relationship with their
    # chassis. This is indicated by the "base_chassis_id" column on the 
    # device table being present.
    #
    def has_direct_chassis?
      !base_chassis_id.nil?
    end

    #
    # chassis
    # 
    # Infers whether this device has a direct or indirect association
    # with a chassis, and returns the appropriate association. This
    # method should be used *Sparingly*. Rails cannot bestow all of 
    # its nifty association powers to you if you're not referring to
    # associations directly.
    #
    def chassis
      if has_direct_chassis?
        direct_chassis
      else
        indirect_chassis
      end
    end

    def cluster
      return @cluster if defined?(@cluster)

      @cluster = 
        if !chassis.nil?
          cluster = chassis.cluster rescue nil
          cluster.nil? ? Ivy::Cluster.first : cluster
        elsif slot.nil?
          Ivy::Cluster.first
        else
          slot.cluster
        end
    end

    #
    # for tagged devices, because they don't have their own template
    #
    def template
      if has_direct_chassis?
        direct_template
      else
        indirect_template
      end
    end

    #
    # rack
    #
    # As with chassis, infers the rack of this device based on whether
    # it has a direct or indirect chassis.
    #
    def rack
      if has_direct_chassis?
        direct_rack
      else
        indirect_rack
      end
    end

    def mia?
      role == 'mia'
    end

    def isla?
      role == 'isla'
    end

    def metrics
      return cache_get && cache_get[:metrics] || {}
    end

    # XXX Perhaps this should be renamed `to_interchange` and it returns a hash
    # instead of mutating one?
    def store_self_in_interchange(d)
      # Reload on creation, otherwise associations (e.g. chassis) may not work.
      reload if created_on_changed?

      d[:name] = name
      # d[:role] = role
      d[:id] = id
      d[:type] = type
      d[:tagged] = tagged
      d[:hidden] = false
      d[:useful] = model.nil? || model != 'Blank Panel'
      d[:map_to_host] = data_source_map ? data_source_map.map_to_host : nil
      d[:chassis_id] = chassis.nil? ? nil : chassis.id
      d[:metrics] ||= {}
      # d[:metrics].delete_if{|k,v| k.match(/ct\.asset\./)} 

      true
    end

    # def update_interchange
    #   super
    #   rack.update_interchange if rack
    #   chassis.update_interchange if chassis
    # end

    # def destroy_interchange
    #   super
    #   rack.update_interchange if rack
    #   chassis.update_interchange if chassis
    # end


    ############################
    #
    # Private Instance Methods
    #
    ############################

    private

    def create_or_update_data_source_map
      if data_source_map.nil?
        build_data_source_map(data_source_id: 1, map_to_grid: 'unspecified', map_to_cluster: 'unspecified')
        data_source_map.save
      elsif data_source_map.map_to_host != data_source_map.calculate_map_to_host && device_should_have_dsm_updated
        data_source_map.update_attribute(:map_to_host, data_source_map.calculate_map_to_host)
      end
    end

    def device_should_have_dsm_updated
      # XXX Add Ivy::Device::PowerDistribution and Ivy::Device::PowerFeed if they ever exist.
      if tagged?
        false
      elsif [Ivy::Device::Sensor, Ivy::Device::PowerStrip].include?(self.class)
        false 
      else
        true
      end
    end

    #
    # name_validator
    #
    # Note: Although tagged devices will also validate, we need to supress the error
    # message for them in order to preserve their anonimity from users. 
    #
    def name_validator
      return unless self.name

      d = Ivy::Device.where(["lower(name) LIKE ?", self.name.downcase]).first
      if(!d.nil? && d.id != self.id)
        errors.add(:name, "'#{d.name}' has already been taken by a #{Ivy::DevicePresenter.new(d).device_type}") if !tagged?
      end    

      # Do not allow the creation of non-tagged devices that have the 
      # same name as a chassis. Tagged devices must be excluded from this
      # check because tagged devices *must* have the same name as their
      # associated chassis.
      unless self.tagged
        if Chassis.pluck(:name).include?(self.name)
          errors.add(:name, "there is already a chassis with that name")
        end
      end
    end

    def device_limit 
      return if tagged
      limit_rads = YAML.load_file("/etc/concurrent-thinking/appliance/release.yml")['device_limit'] rescue nil
      limit_nrads = YAML.load_file("/etc/concurrent-thinking/appliance/release.yml")['nrad_limit'] rescue nil
      return unless limit_rads && limit_nrads
      current = Ivy::Device.all.size - Ivy::Device.blank.size - Ivy::Device::RackTaggedDevice.all.size
      # current -= Ivy::Device.sensors.size #+ Ivy::Device::VirtualServer.all.size
      return if current < (limit_rads + limit_nrads)
      self.errors.add(:base, "The device limit of #{limit_rads+limit_nrads} has been exceeded")
    end 
  end
end

# XXX Consider replacing this with an inherited hook.
Dir["#{File.dirname(__FILE__)}/device/**.rb"].each do |d|
  file_name = File.basename(d, '.rb')
  require "ivy/device/#{file_name}"
  unless [ 'sensor' ].include? file_name
    Ivy::Device.types << "Ivy::Device::#{file_name.classify}".constantize
  end
end
