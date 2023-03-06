module Ivy
  module Concerns
    #
    # Opionated methods for storing objects in the memcache interchange.
    #
    module Interchange
      
      extend ActiveSupport::Concern

      included do
        after_save :update_interchange
        after_destroy :destroy_interchange
      end

      class_methods do
        # Returns the key at which the list of instances is stored in the
        # interchange e.g., `hacor:devices`.
        def interchange_list
          mod, klass = [base_class.name.deconstantize, base_class.name.demodulize]
          mod = 'Hacor' if mod = 'Ivy'
          [mod, klass.pluralize]
            .map { |i| i.downcase }
            .join(':')
        end

        def preheat_interchange
          MemcachePreheater.preheat_interchange(self, all)
        end

        # Add the given instance to the given list.
        #
        # The list is the list as it exists in the interchange.  The instance
        # is the ActiveRecord instance.
        def store_list_in_interchange(list, instance)
          list << instance.memcache_key unless list.include?(instance.memcache_key)
        end

      end

      # +update_interchange+ stores the instance in the interchange and updates
      # the interchange list of instances.
      #
      # If any additional bookkeeping is required, override the method and call
      # `super`.
      def update_interchange
        MemcachePreheater.heat(self)
        MemcachePreheater.add_list_interchange(self, self.class)
      end

      # +update_interchange+ removes the instance in the interchange and updates
      # the interchange list of instances.
      #
      # If any additional bookkeeping is required, override the method and call
      # `super`.
      def destroy_interchange
        MemcachePreheater.delete_list_interchange(self, self.class)
        cache_wrapper.delete(memcache_key)
      end


      # Returns the key at which the instances is stored in the interchange e.g.,
      # `hacor:device:40`.
      def memcache_key
        "#{self.class.interchange_list.singularize}:#{id}"
      end

      # Returns the instance as stored in the interchange.
      def cache_get
        cache_wrapper.get(memcache_key)
      end

      def cache_wrapper
        MemcachePreheater.cache_wrapper
      end
    end
  end
end
