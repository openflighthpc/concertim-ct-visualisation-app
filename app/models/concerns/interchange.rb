#
# Opinionated methods for storing objects in the memcache interchange.
#
# Uses an +Interchange::Repo+ to manage life cycle hooks: create, save and destroy.
#
# Provides a +preheat_interchange+ method for +Phoenix::Cache::Preheater+'s
# to hook into.
#
module Interchange

  extend ActiveSupport::Concern

  included do
    after_save :update_interchange
    after_destroy :remove_from_interchange
  end

  class_methods do
    # Returns the key at which the list of instances is stored in the
    # interchange e.g., `hacor:devices`.
    def interchange_list_key
      mod, klass = [base_class.name.deconstantize, base_class.name.demodulize]
      mod = 'Hacor' # not certain if mod logic still required
      [mod, klass.pluralize]
        .map { |i| i.downcase }
        .join(':')
    end

    # Store all instances in the interchange.
    def preheat_interchange
      interchange_repo.store_instances
    end

    # Return the interchange repo.
    #
    # The repo defines how instances are stored in the interchange.
    def interchange_repo
      Interchange::Repo.new(self, MEMCACHE, MEMCACHE.logger)
    end
  end

  # +update_interchange+ stores the updated (or new) instance in the
  # interchange.
  #
  # If any additional bookkeeping is required, override the method and call
  # `super`.
  def update_interchange
    self.class.interchange_repo.update_instance(self)
  end

  # +remove_from_interchange+ removes the instance in the interchange.
  #
  # If any additional bookkeeping is required, override the method and call
  # `super`.
  def remove_from_interchange
    self.class.interchange_repo.remove_instance(self)
  end

  # Returns the key at which the instances is stored in the interchange e.g.,
  # `hacor:device:40`.
  def interchange_key
    "#{self.class.interchange_list_key.singularize}:#{id}"
  end

  # Returns the data stored for the instance in the interchange.
  def interchange_data
    self.class.interchange_repo.get(self)
  end
end
