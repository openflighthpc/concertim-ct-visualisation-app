module Ivy
  class Device < ApplicationRecord
    self.table_name = "devices"

    include Ivy::Concerns::Interchange
    include Ivy::Concerns::LiveUpdate::Device


    #############################
    #
    # CONSTANTS
    #
    ############################

    VALID_STATUSES = %w(IN_PROGRESS FAILED ACTIVE STOPPED SUSPENDED)
    VALID_STATUS_ACTION_MAPPINGS = {
      "IN_PROGRESS" => [],
      "FAILED" => [],
      "ACTIVE" => %w(destroy off suspend),
      "STOPPED" => %w(destroy on),
      "SUSPENDED" => %w(destroy resume)
    }

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
    validates :status,
      presence: true,
      inclusion: { in: VALID_STATUSES, message: "must be one of #{VALID_STATUSES.to_sentence(last_word_connector: ' or ')}" }
    validates :cost,
      numericality: { greater_than_or_equal_to: 0 },
      allow_blank: true
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

    def valid_action?(action)
      VALID_STATUS_ACTION_MAPPINGS[status].include?(action)
    end

    def openstack_id
      metadata['openstack_instance']
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
      return unless location.present?

      taken_names = Ivy::Device
        .joins(chassis: :location)
        .where(location: {rack_id: location.rack_id})
        .where.not(id: id)
        .pluck(:name)

      if taken_names.include?(name)
        errors.add(:name, :taken)
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
