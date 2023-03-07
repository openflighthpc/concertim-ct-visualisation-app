module Ivy
  module Concerns
    #
    # Opionated methods for storing objects in the memcache interchange.
    #
    # Uses an +Interchange::Repo+ to manaage life cycle hooks: create, save and destroy.
    #
    # Provides a +preheat_interchange+ method for +Phoenix::Cache::Preheater+'s
    # to hook into.
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
        def interchange_list_key
          mod, klass = [base_class.name.deconstantize, base_class.name.demodulize]
          mod = 'Hacor' if mod == 'Ivy'
          [mod, klass.pluralize]
            .map { |i| i.downcase }
            .join(':')
        end

        def preheat_interchange
          interchange_repo.store_instances
        end

        private

        # Returns the interchange client
        def interchange
          MEMCACHE
        end

        def interchange_repo
          ::Ivy::Interchange::Repo.new(self, interchange, interchange.logger)
        end
      end

      # +update_interchange+ stores the instance in the interchange and updates
      # the interchange list of instances.
      #
      # If any additional bookkeeping is required, override the method and call
      # `super`.
      def update_interchange
        interchange_repo.store_instance(self)
        interchange_repo.add_instance_to_list(self)
      end

      # +update_interchange+ removes the instance in the interchange and updates
      # the interchange list of instances.
      #
      # If any additional bookkeeping is required, override the method and call
      # `super`.
      def destroy_interchange
        interchange_repo.remove_instance_from_list(self)
        interchange.delete(interchange_key)
      end

      # Returns the key at which the instances is stored in the interchange e.g.,
      # `hacor:device:40`.
      def interchange_key
        "#{self.class.interchange_list_key.singularize}:#{id}"
      end

      # Returns the interchange client
      def interchange
        self.class.interchange
      end

      # Returns the interchange heater
      def interchange_repo
        self.class.interchange_repo
      end

      # Returns the data stored for the instance in the interchange.
      def interchange_data
        interchange.get(interchange_key)
      end
    end
  end
end
