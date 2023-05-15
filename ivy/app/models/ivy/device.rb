module Ivy
  class Device < ApplicationRecord
    self.table_name = "devices"

    include Ivy::Concerns::Interchange
    include Ivy::Concerns::LiveUpdate::Device


    ####################################
    #
    # Associations
    #
    ####################################

    has_one :data_source_map, dependent: :destroy 

    belongs_to :slot
    has_one :chassis_row, through: :slot, class_name: 'Ivy::ChassisRow'
    has_one :chassis, through: :chassis_row, class_name: "Ivy::Chassis"
    has_one :rack, through: :chassis, source: :rack

    has_one :template, through: :chassis, source: :template


    ###########################
    #
    # Validations
    #
    ###########################

    validates :name,
      presence: true,
      length: { maximum: 150 },
      format: {
        with: /\A[a-zA-Z0-9\-]*\Z/,
        message: "can contain only alphanumeric characters and hyphens."
      }
    validates :slot_id, uniqueness: true, allow_nil: true
    validates :slot_id, presence: true
    validate :name_validator
    validate :device_limit, if: :new_record? 

    #############################
    #
    # Scopes 
    #
    #############################

    scope :occupying_rack_u, ->{ joins(:rack).where(base_chassis: {type: :RackChassis}) }

    ####################################
    #
    # Delegation 
    #
    ####################################

    delegate :model,
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
    # :remove_metrics


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
    
    def metrics
      interchange_data && interchange_data[:metrics] || {}
    end

    def to_interchange_format(data)
      # Reload on creation, otherwise associations (e.g. chassis) may not work.
      reload if created_at_previously_changed? || created_at_changed?

      # Overwrite these if already set.
      data.merge!(
        name: name,
        id: id,
        hidden: false,
        useful: model.nil? || model != 'Blank Panel',
        map_to_host: data_source_map.nil? ? nil : data_source_map.map_to_host,
        chassis_id: chassis.nil? ? nil : chassis.id,
      )

      # Set metrics to its default unless already set.
      data[:metrics] ||= {}
    end


    ############################
    #
    # Private Instance Methods
    #
    ############################

    private

    def create_or_update_data_source_map
      if data_source_map.nil?
        build_data_source_map
        data_source_map.save
      elsif data_source_map.map_to_host != data_source_map.calculate_map_to_host
        data_source_map.update_attribute(:map_to_host, data_source_map.calculate_map_to_host)
      end
    end

    #
    # name_validator
    #
    def name_validator
      return unless self.name

      d = Ivy::Device.where(["lower(name) LIKE ?", self.name.downcase]).first
      if(!d.nil? && d.id != self.id)
        errors.add(:name, "'#{d.name}' has already been taken by a #{Ivy::DevicePresenter.new(d).device_type}")
      end    

      # Do not allow the creation of devices that have the same name as a
      # chassis.
      if Chassis.pluck(:name).include?(self.name)
        errors.add(:name, "there is already a chassis with that name")
      end
    end

    def device_limit 
      limit_rads = YAML.load_file("/opt/concertim/licence-limits.yml")['device_limit'] rescue nil
      limit_nrads = YAML.load_file("/opt/concertim/licence-limits.yml")['nrad_limit'] rescue nil
      return unless limit_rads && limit_nrads
      current = Ivy::Device.all.size
      return if current < (limit_rads + limit_nrads)
      self.errors.add(:base, "The device limit of #{limit_rads+limit_nrads} has been exceeded")
    end
  end
end

# XXX Consider replacing this with an inherited hook.
Dir["#{File.dirname(__FILE__)}/device/**.rb"].each do |d|
  file_name = File.basename(d, '.rb')
  require "ivy/device/#{file_name}"
  Ivy::Device.types << "Ivy::Device::#{file_name.classify}".constantize
end
