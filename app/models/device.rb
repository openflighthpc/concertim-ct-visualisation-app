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


  ####################################
  #
  # Class Methods
  #
  ####################################

  def self.valid_statuses
    []
  end

  def self.valid_status_action_mappings
    {}
  end

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
  validates :status, presence: true
  validate :status_validator
  validates :cost,
            numericality: { greater_than_or_equal_to: 0 },
            allow_blank: true
  validates :details, presence: :true
  validate :name_validator
  validate :device_limit, if: :new_record?
  validate :metadata_format
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
    self.class.valid_status_action_mappings[status].include?(action)
  end

  def subtype
    self.class.name.downcase.pluralize
  end

  def data_map_class_name
    "device"
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

  def status_validator
    return unless self.status

    unless self.class.valid_statuses.include?(self.status)
      errors.add(:status, "must be one of #{self.class.valid_statuses.to_sentence(last_word_connector: ' or ')}")
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

  def details_type_not_changed
    if details_type_changed? && self.persisted?
      self.errors.add(:details_type, "Cannot be changed once a device has been created")
    end
  end
end
