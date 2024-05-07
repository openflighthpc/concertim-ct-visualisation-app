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
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

# Encapsulates logic around updating +modified_timestamp+ attributes to
# support live updates on the IRV.
#
# For the IRV:
#
# 1) moving a chassis from one location to another should update the
# timestamp of the racks being moved to/from.
#
# 2) moving blades (aka +Device+s) from one enclosure slot (aka +Slot+) to
# another should update the timestamp of the enclosures (aka +Chassis+)
# being moved to/from.  It should also update the timestamp of the racks
# those chassis are in if any.
module LiveUpdate

  # Maintains a modified_timestamp field and allows for querying records
  # modified after a certain time.
  module HasModifiedTimestamp
    extend ActiveSupport::Concern

    included do
      before_save :set_modified_timestamp

      scope :modified_after, ->(timestamp) { where("modified_timestamp > ?", timestamp.to_i) }
    end

    def update_modified_timestamp
      save!
    end

    private

    def set_modified_timestamp
      self.modified_timestamp = Time.now.to_i
    end
  end

  module HwRack
    extend ActiveSupport::Concern
    include HasModifiedTimestamp
  end

  module Location
    extend ActiveSupport::Concern
    # include HasModifiedTimestamp

    included do
      # We don't update after create as we assume that either chassis or
      # device will do so.
      after_update :update_rack_modified_timestamp
    end

    # Update the relevant racks when moving location.
    def update_rack_modified_timestamp
      current_rack = rack
      previous_rack = rack_id_previously_changed? ? HwRack.find(rack_id_previously_was) : nil
      current_rack.update_modified_timestamp unless current_rack.nil?
      previous_rack.update_modified_timestamp unless previous_rack.nil?
    end
  end

  module Chassis
    extend ActiveSupport::Concern
    include HasModifiedTimestamp

    included do
      # Simple chassis will update the rack modified timestamp when the
      # device is created.  We avoid doing it here too to avoid (1)
      # unnecessary work and (2) potentially having a partially created
      # simple chassis appear on the rack.
      after_create :update_rack_modified_timestamp, if: :complex?
      after_destroy :update_rack_modified_timestamp, unless: :being_destroyed_as_dependent?
    end

    # Update the relevant racks when moving location.
    def update_rack_modified_timestamp
      return if location.nil?
      return if location.rack.nil?
      location.rack.update_modified_timestamp
    end

    # Update either this chassis modified_timestamp or this chassis's rack's
    # modified_timestamp.
    def update_modified_timestamp_of_chassis_or_rack
      if nonrack? && id.present?
        update_modified_timestamp
      else
        update_rack_modified_timestamp
      end
    end

    private

    def being_destroyed_as_dependent?
      destroyed_by_association.present?
    end

  end

  module Device
    extend ActiveSupport::Concern

    included do
      delegate :update_modified_timestamp,
               to: :chassis, allow_nil: true

      # Maintain modification timestamps for self and associated chassis.
      after_save :update_modified_timestamp, :update_rack_modified_timestamp
      before_destroy :update_modified_timestamp
      after_destroy :update_rack_modified_timestamp, unless: :being_destroyed_as_dependent?
    end

    private

    # Update the modified_timestamp of the relevant parent.
    #
    # The relevant parent might be a chassis or a rack.  That determination is
    # made in the chassis class.
    #
    # If the relevant parent has changed (such a blade being moved from one
    # blade enclosure to another) both the current and previous parents are
    # updated.
    def update_rack_modified_timestamp
      current_chassis = chassis

      previous_chassis =
        if base_chassis_id_previously_changed? && !base_chassis_id_previously_was.nil?
          ::Chassis.find(base_chassis_id_previously_was)
        else
          nil
        end

      if current_chassis.present?
        current_chassis.update_modified_timestamp_of_chassis_or_rack
      end
      if previous_chassis.present?
        previous_chassis.update_modified_timestamp_of_chassis_or_rack
      end
    end

    def being_destroyed_as_dependent?
      destroyed_by_association.present?
    end
  end
end
