#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

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
    "ACTIVE" => %w(destroy off suspend detach),
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
  has_one :team, through: :rack

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
              with: /\A[a-zA-Z0-9\-\.]*\Z/,
              message: "can contain only alphanumeric characters, dots and hyphens."
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
  validate :details_type_not_changed
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
    # return false unless compute_device? || action ==  "destroy"

    VALID_STATUS_ACTION_MAPPINGS[status].include?(action)
  end

  def compute_device?
    self.details_type == "Device::ComputeDetails"
  end

  # This suggests we probably do/will need subclasses
  def subtype
    self.details_type == "Device::ComputeDetails" ? "instances" : self.details_type[/::(\w+)Details/, 1].downcase << "s"
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

  def details_type_not_changed
    if details_type_changed? && self.persisted?
      self.errors.add(:details_type, "Cannot be changed once a device has been created")
    end
  end
end
