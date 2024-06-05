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

# Hardware Rack - cannot call Rack as conflicts with the module defined in the Rack gem used by Rails
class HwRack < ApplicationRecord

  self.table_name = "racks"

  include Templateable
  include HwRack::Occupation
  include LiveUpdate::HwRack


  #############################
  #
  # CONSTANTS
  #
  ############################

  VALID_STATUSES = %w(IN_PROGRESS FAILED ACTIVE STOPPED)
  VALID_STATUS_ACTION_MAPPINGS = {
    "IN_PROGRESS" => [],
    "FAILED" => %w(destroy),
    "ACTIVE" => %w(destroy),
    "STOPPED" => %w(destroy)
  }

  ############################
  #
  # Associations
  #
  ############################

  has_many :locations, ->{ order(start_u: :desc) },
           foreign_key: :rack_id,
           dependent: :destroy

  has_many :chassis, through: :locations
  has_many :devices, through: :chassis

  belongs_to :team
  belongs_to :cluster_type

  ############################
  #
  # Validations
  #
  ############################

  validates :name,
            presence: true,
            uniqueness: {scope: :team},
            format: {
              with: /\A[a-zA-Z0-9\-\_]*\Z/,
              message: "can contain only alphanumeric characters, hyphens and underscores."
            }
  validates :u_depth, numericality: { only_integer: true, greater_than: 0 }
  validates :u_height, numericality: { only_integer: true, greater_than: 0, less_than: 73 }
  validate :u_height_greater_than_highest_occupied_u?, unless: :new_record?
  validates :status,
            presence: true,
            inclusion: { in: VALID_STATUSES, message: "must be one of #{VALID_STATUSES.to_sentence(last_word_connector: ' or ')}" }
  validates :cost,
            numericality: { greater_than_or_equal_to: 0 },
            allow_blank: true
  validates :order_id,
    presence: true,
    uniqueness: true
  validates :cloud_created_at, presence: true
  validate :rack_limit, if: :new_record?
  validate :metadata_format

  ############################
  #
  # Defaults
  #
  ############################

  def set_defaults
    self.u_depth ||= 2
    self.template_id ||= Template.default_rack_template&.id

    # The remaining defaults take their value from that given to the last
    # rack.
    last_rack = HwRack.where(team: team).order(:created_at).last

    self.u_height ||= last_rack.nil? ? 42 : last_rack.u_height
    self.name ||=
      if last_rack
        last_rack.name.sub(/(\d+)(\D*$)/) do |m|
          sprintf("%0#{$1.length}d%s", $1.to_i + 1, $2)
        end
      else
        "Rack-#{HwRack.where(team: team).count + 1}"
      end
  end

  ######################################
  #
  # Hooks
  #
  ######################################
  after_initialize :set_defaults, if: Proc.new {|r| r.new_record? }

  after_commit on: :create do
    broadcast_change("added")
  end
  after_commit on: :update do
    broadcast_change("modified")
  end
  after_commit on: :destroy do
    broadcast_change("deleted")
  end

  ####################################
  #
  # Scopes
  #
  ####################################

  scope :excluding_ids,  ->(ids) { where.not(id: ids) }

  def self.find_by_openstack_id(openstack_stack_id)
    where("metadata ->> 'openstack_stack_id' = ?", openstack_stack_id).first
  end


  ############################
  #
  # Class Methods
  #
  ############################

  def self.get_canvas_config
    JSON.parse(File.read(Rails.root.join("app/views/racks/_configuration.json")))
  end

  ############################
  #
  # Instance Methods
  #
  ############################

  def cluster_type_name=(name)
    self.cluster_type = ClusterType.find_by(foreign_id: name)
  end

  def valid_action?(action)
    VALID_STATUS_ACTION_MAPPINGS[status].include?(action)
  end

  def openstack_id
    metadata["openstack_stack_id"]
  end

  def credit_allocation
    devices.reduce(0) { |sum, device| sum + device.credit_allocation }
  end

  def hourly_credits
    devices.reduce(0) { |sum, device| sum + device.hourly_credits }
  end

  ############################
  #
  # Private Instance Methods
  #
  ############################

  private

  #
  # u_height is not allowed to be lower than space used.
  #
  def u_height_greater_than_highest_occupied_u?
    return if u_height.nil?
    if !(u_height >= highest_empty_u)
      self.errors.add(:u_height, "must be greater than the highest occupied U (minimum is therefore #{highest_empty_u}).")
    end
  end

  def rack_limit
    limit = YAML.load_file("/opt/concertim/licence-limits.yml")['rack_limit'] rescue nil
    return if limit.nil? || HwRack.count < limit
    self.errors.add(:base, "The rack limit of #{limit} has been exceeded")
  end

  def metadata_format
    self.errors.add(:metadata, "Must be an object") unless metadata.is_a?(Hash)
  end

  def broadcast_change(action)
    BroadcastRackChangeJob.perform_now(self.id, self.team_id, action)
  end
end
