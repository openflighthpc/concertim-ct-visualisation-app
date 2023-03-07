module Ivy
  module Interchange
    #
    # Store instances and collections of instances in the interchange.
    #
    # The `Ivy::Concerns::Interchange` concern provides common hooks and entry
    # points to using this class.  Use like so:
    #
    # ```
    # class Foo::Bar < ActiveRecordBase
    #   include Ivy::Concerns::Interchange
    #
    #   # Return the data for the instance that should be merged with the data
    #   # currently in the interchange.
    #   def to_interchange_format
    #     { some: :value }
    #   end
    #
    #   # Alternatively, if +to_interchange_format+ takes a single argument, say,
    #   # +data+, it is # called with +data+ set to the data currenty in the
    #   # interchange.
    #   #
    #   # The interchange is updated by modifying +data+ in place.
    #   def to_interchange_format(data)
    #     data.delete[:foo]
    #     data[:bar] ||= 'bar'
    #     data[:baz] = 'baz'
    #   end
    # end
    # ```
    #
    # As records of Foo::Bar are created and destroyed, the `foo:bars`
    # interchange key will be kept updated with a list of existing Foo::Bars.
    # Individual `foo:bar:<ID>` interchange keys will also be updated.
    #
    class Repo
      include Phoenix::Cache::Locking

      def initialize(klass, cache, logger)
        @klass = klass
        @cache = cache
        @logger = logger
      end

      # Store all +instances+ for +@klass+ in the interchange and update the
      # interchange list with each stored instance.
      #
      # The following, would 1) updated the interchange key `hacor:devices` with
      # interchange key for all devices; and 2) update the interchange key
      # `hacor:device:<ID>` for each Ivy::Device.
      #
      #     InterchangeHeater.new(Ivy::Device, ...).preheat()
      #
      def store_instances
        @logger.info("Preheating model #{@klass.to_s}")
        start = Time.now.to_i

        instances = @klass.all
        failed_ids = instances.map(&:id)
        retries = 10

        # try to preheat a number of times
        while retries > 0 && failed_ids.size > 0
          # lock the global list, if it exists, and update the elements
          if @klass.interchange_list_key.nil? 
            try_store_instances(nil, instances, failed_ids)
          else
            locked_modify(@klass.interchange_list_key, :default => []) do |list|
              try_store_instances(list, instances, failed_ids)
            end
          end
          retries -= 1
          sleep 3 if retries > 0 && failed_ids.size > 0
        end

        # pass back the failed ids, if any
        time_taken = Time.now.to_i - start
        failed_ids.each {|id| @logger.warn("Failed to preheat #{@klass.to_s}:#{id}")}
        @logger.info("Completed model #{@klass.to_s} in #{time_taken} secs")
        failed_ids
      end

      # Add the given instance to the interchange list of such instances.
      #
      # The following would update the interchange key `hacor:devices` by
      # appending the new devices interchange key.
      #
      #     add_instance_to_list(Ivy::Device.create!())
      def add_instance_to_list(instance)
        locked_modify(@klass.interchange_list_key, :default => []) do |list|
          add_instance_to_list(list, instance)
        end
      end

      def remove_instance_from_list(instance)
        locked_modify(@klass.interchange_list_key, :default => []) do |list|
          list.delete(instance.interchange_key)
        end
      end

      # Store the given instance in the interchange.
      #
      #
      def store_instance(instance)
        locked_modify(instance.interchange_key, :default => {}) do |data|
          to_interchange_format = instance.method(:to_interchange_format)
          if to_interchange_format.arity == 0
            data.merge!(to_interchange_format.call)
          else
            to_interchange_format.call(data)
          end
        end
      end

      private

      def cache
        @cache
      end

      def add_instance_to_list(list, instance)
        list << instance.interchange_key unless list.include?(instance.interchange_key)
      end

      # Attempt to store each instance in interchange; update +list+ with each
      # success; remove each success from failed_ids.
      def try_store_instances(list, instances, failed_ids)
        instances.each do |instance|
          begin
            if failed_ids.include?(instance.id)
              store_instance(instance)
              add_instance_to_list(list, instance) unless list.nil?
              failed_ids.delete(instance.id)
            end
          rescue Exception => e
            # we'll try again next time
            logger.warn("#{e.message} - #{e.backtrace.inspect}")
          end
        end
      end
    end
  end
end
