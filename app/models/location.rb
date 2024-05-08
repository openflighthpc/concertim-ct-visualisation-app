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

class Location < ApplicationRecord
  include LiveUpdate::Location

  #######################
  #
  # Associations
  #
  #######################

  # For now the rack association is non-optional.  When support for non-rack
  # locations is added this may change.
  belongs_to :rack, :class_name => "HwRack"

  has_one :chassis,
          dependent: :destroy
  has_one :device, through: :chassis


  ####################################
  #
  # Hooks
  #
  ####################################

  before_validation :calculate_rack_end_u


  #######################
  #
  # Validations
  #
  # The validations here assume that only rack locations are valid.  These
  # will need to change when support for non-rack locations is added.
  #
  #######################

  validates :u_height,
            numericality: { only_integer: true, greater_than: 0 }
  validates :u_depth,
            numericality: { only_integer: true, greater_than: 0 }
  validates :start_u,
            numericality: { only_integer: true, greater_than: 0 }
  validates :end_u,
            numericality: { only_integer: true, greater_than: 0 }
  validates :facing,
            inclusion: { in: %w( b f ), permitted: %w( b f ), message: "must be either 'b' or 'f'" }

  validates :rack,
            presence: true
  validate :rack_has_not_changed

  validate :start_u_is_valid
  validate :target_u_is_empty


  #######################
  #
  # Scopes
  #
  #######################

  # Locations *in* a rack.  That is, exactly those for which `in_rack?` would return true.
  scope :occupying_rack_u, ->{ all }

  #######################
  #
  # Instance Methods
  #
  #######################

  def calculate_rack_end_u
    self.end_u = start_u.nil? ? nil : start_u + ( u_height || 1 ) - 1
  end

  # in_rack? returns true if the location is *in* a rack, i.e., it occupies a
  # rack U.  Non-rack locations and zero-u locations do not.
  def in_rack?
    true
  end

  # has_rack? returns true if the location has a rack.  That is either it is
  # in or on a rack. Non-rack chassis do not have a rack, others should.
  def has_rack?
    true
  end

  # zero_u? returns true if the location is a zero_u location.  That is the
  # location is *on* a rack but not *in* a rack.  It does not occupy any of
  # the rack's Us.
  def zero_u?
    false
  end

  # nonrack? returns true if the location is not associated with a rack.
  def nonrack?
    false
  end

  # position returns the position of a zero-u location;  one of `:t`, `:m`,
  # `:b` for top, middle or bottom.
  #
  def position
    return nil unless has_rack? && zero_u?

    case start_u
    when 1
      :b
    when rack.u_height
      :t
    else
      :m
    end
  end

  # occupy_u? returns true if the location occupies the given u on the given
  # facing.
  #
  # If the location is full depth, it occupies both facings at that U,
  # otherwise it only occupies the facing that it faces.
  def occupy_u?(rack_u, facing:nil, exclude:nil)
    return false if self.id == exclude
    return false unless in_rack?

    # If the chassis starts after the U or ends before it it doesn't occupy
    # it.
    return false if self.start_u > rack_u
    return false if self.end_u < rack_u

    # Otherwise the chassis occupies the U if it is full depth, or we don't
    # care about the facing, or it matches the given facing.
    if full_depth?
      true
    elsif facing.nil?
      true
    elsif self.facing == facing
      true
    else
      false
    end
  end

  def update_position(params)
    self.facing = params[:facing]
    self.start_u = params[:start_u]
    # XXX Consider if show_in_dcrv is: 1) no longer needed; 2) a chassis
    # property; 3) a location property.
    chassis.show_in_dcrv = params[:show_in_dcrv] unless params[:show_in_dcrv].nil?

    unless params[:type].nil? || params[:type] == 'RackChassis'
      raise NotImplementedError, "Only rack locations currently supported"
    end
  end


  def full_depth?
    return nil unless in_rack?
    u_depth == rack.u_depth
  end

  #############################
  #
  # Private Methods
  #
  #############################

  private

  def start_u_is_valid
    return if start_u.nil?
    return if end_u.nil?

    if start_u > rack.u_height || start_u < 1
      errors.add(:start_u, 'is invalid')
    end
    if end_u > rack.u_height
      errors.add(:end_u, 'is invalid')
    end
  end

  def target_u_is_empty
    return if rack.nil?
    return if u_depth.nil?
    return if facing.nil?
    return if start_u.nil?

    is_full_depth = u_depth == rack.u_depth
    facing = is_full_depth ? nil : self.facing
    return if rack.u_is_empty?(start_u, exclude: self.id, facing: facing)

    errors.add(:start_u, 'is occupied')
  rescue HwRack::Occupation::InvalidRackU
    errors.add(:start_u, 'is invalid')
  end

  def rack_has_not_changed
    return if !persisted?
    if rack_id_changed?
      errors.add(:rack_id, "cannot be updated")
    end
  end
end
