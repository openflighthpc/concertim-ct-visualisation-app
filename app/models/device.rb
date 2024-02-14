class Device < ApplicationRecord

  include LiveUpdate::Device

  include Searchable
  default_search_scope :name, :status

  #############################
  #
  # CONSTANTS
  #
  ############################

  VALID_STATUSES = %w(IN_PROGRESS FAILED ACTIVE STOPPED SUSPENDED)
  VALID_STATUS_ACTION_MAPPINGS = {
    "IN_PROGRESS" => [],
    "FAILED" => %w(destroy),
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

  belongs_to :details, polymorphic: :true, dependent: :destroy


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
  validates :details, presence: :true
  validate :name_validator
  validate :device_limit, if: :new_record?
  validate :metadata_format
  validate :valid_details_type
  validates_associated :details

  #############################
  #
  # Scopes
  #
  #############################

  scope :occupying_rack_u, ->{ joins(:chassis).where(base_chassis: {location: Location.occupying_rack_u}) }

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

  def valid_action?(action)
    VALID_STATUS_ACTION_MAPPINGS[status].include?(action)
  end

  def openstack_id
    metadata['openstack_instance_id']
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

    taken_names = Device
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
    current = Device.all.size
    return if current < (limit_rads + limit_nrads)
    self.errors.add(:base, "The device limit of #{limit_rads+limit_nrads} has been exceeded")
  end

  def metadata_format
    self.errors.add(:metadata, "Must be an object") unless metadata.is_a?(Hash)
  end

  def valid_details_type
    return unless details_type.present?
    begin
      dt = details_type.constantize
      self.errors.add(:details_type, "Must be a valid subtype of Device::Details") unless dt < Device::Details
    rescue NameError
      self.errors.add(:details_type, "Must be a valid and recognised type")
    end
  end
end
