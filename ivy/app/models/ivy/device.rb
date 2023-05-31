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

    belongs_to :chassis, foreign_key: :base_chassis_id
    has_one :rack, through: :chassis, source: :rack
    has_one :location, through: :chassis, source: :location

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
    validate :name_validator
    validate :device_limit, if: :new_record? 
    validate :metadata_format

    #############################
    #
    # Scopes 
    #
    #############################

    scope :occupying_rack_u, ->{ joins(:chassis).where(base_chassis: {location: Ivy::Location.occupying_rack_u}) }

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

    def metadata_format
      self.errors.add(:metadata, "Must be an object") unless metadata.is_a?(Hash)
    end
  end
end
