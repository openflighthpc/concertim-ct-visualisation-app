module Ivy
  module Concerns
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

      module Chassis
        extend ActiveSupport::Concern
        include HasModifiedTimestamp

        included do
          # Simple chassis will update the rack modified timestamp when the
          # device is created.  We avoid doing it here too to avoid (1)
          # unnecessary work and (2) potentially having a partially created
          # simple chassis appear on the rack.
          after_create :update_rack_modified_timestamp, if: :complex?
          after_update :update_rack_modified_timestamp
        end

        # Update the relevant racks when moving location.
        def update_rack_modified_timestamp
          current_rack = rack
          previous_rack = rack_id_previously_changed? ? Ivy::HwRack.find(rack_id_previously_was) : nil
          current_rack.update_modified_timestamp unless current_rack.nil?
          previous_rack.update_modified_timestamp unless previous_rack.nil?
        end

        # Update either this chassis modified_timestamp or this chassis's rack's
        # modified_timestamp.
        def update_modified_timestamp_of_chassis_or_rack
          if nonrack?
            update_modified_timestamp
          else
            update_rack_modified_timestamp
          end
        end

      end

      module Slot
        extend ActiveSupport::Concern

        included do
          # FSR legacy allowed a nil chassis here.  Why? Do we still need it?
          delegate :update_rack_modified_timestamp,
            to: :chassis, allow_nil: true
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
          after_destroy :update_rack_modified_timestamp
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
          current_slot = slot
          previous_slot = slot_id_previously_changed? ? Ivy::Slot.find(slot_id_previously_was) : nil

          if current_slot.present? && current_slot.chassis.present?
            current_slot.chassis.update_modified_timestamp_of_chassis_or_rack
          end
          if previous_slot.present? && previous_slot.chassis.present?
            previous_slot.chassis.update_modified_timestamp_of_chassis_or_rack
          end
        end
      end
    end
  end
end
