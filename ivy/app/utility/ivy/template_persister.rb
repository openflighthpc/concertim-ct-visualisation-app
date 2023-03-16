module Ivy
  # Takes a template and user-provided data and creates the appropriate records
  # for it. Appropriate records is a little vague, let's explain below.
  #
  # Simple templates
  # ================
  #
  # If the template is simple? (i.e., it is not a blade enclosure) the
  # following will be created directly by this class.
  #
  # * one chassis;
  # * one chassis row;
  # * one slot;
  # * one device;
  #
  # Other records may be created as a result of those being saved, for instance
  # saving the device may create a data source map, but that is outside of our
  # consideration here.
  #
  # Complex templates
  # =================
  #
  # Complex templates are currently not supported.  They are currently not
  # required and are likely to disappear entirely.
  #
  class TemplatePersister

    class Result < Struct.new(:chassis, :success?, :failed_record); end
    class FailedObjectNotFound < RuntimeError; end
    class UnsupportedError < RuntimeError; end

    # +template+ is the Template instance that is being persisted.
    # +params+ are the params that have been gathered from the user, e.g.,
    # location and name.
    def initialize(template, chassis_params, device_params)
      @template = template
      @chassis_params = chassis_params
      @device_params = device_params
    end

    def call
      raise UnsupportedError, "complex chassis are not supported" if @template.complex?

      Rails.logger.debug("Persisting template #{@template.id}")
      Ivy::Chassis.transaction do
        create_object_graph
      end
      Result.new(@chassis, true, nil)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      Rails.logger.debug("Failed to save chassis: #{$!.message}")
      Result.new(@chassis, false, $!.record)
    end

    private

    # Build an object graph starting at Chassis and containing its rows, slots
    # and device.
    #
    # Ideally we would create the entire object graph in memory and then call
    # `@chassis.save!`.  Unfortunately, this doesn't work for us, as the
    # foreign keys are not propagated down the graph.  This might be something
    # that ActiveRecord doesn't support or it might be due to the way that we
    # have multiple associations using the same foreign keys, e.g.,
    # Chassis#slot/Chassis#slots.  If that relationship is ever simplified, we
    # should consider revisiting this and seeing if it can be simplified too.
    def create_object_graph
      @chassis = Ivy::Chassis::RackChassis.create!(chassis_params)
      row = @chassis.chassis_rows.create!
      slot = row.slots.create!(chassis_row_location: 1)
      device = slot.create_device!(device_params)
      Rails.logger.debug("Built object graph") {
        {chassis: @chassis, row: row, slot: slot, device: device}
      }
    end

    def chassis_params
      @chassis_params.merge(
        template: @template,
        u_height: @template.height,
        u_depth: @template.depth,
      )
    end

    def device_params
      @device_params.merge(
        type: @template.chassis_type
      )
    end
  end
end
