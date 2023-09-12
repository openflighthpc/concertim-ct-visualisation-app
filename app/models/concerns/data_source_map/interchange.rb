#
# Functionality for storing DataSourceMap's in the interchange.  It's
# extracted here just to group it all togther.
#
module DataSourceMap::Interchange

  # Maintains to maps. One from device id to map to host and the other
  # from map to host to device id.  The serialization of these two maps
  # is what is stored in the interchange.
  class Repo
    include Phoenix::Cache::Locking

    def initialize
      @key = "hacor:data_source_map"
      @klass = DataSourceMap
      @logger = cache.logger
    end

    # Updates the two maps with the given instances.
    def store_instances(instances)
      @logger.info("Preheating model #{@klass.to_s}")
      start = Time.now.to_i
      locked_modify(@key) do |map|
        instances.each do |instance|
          add_instance(map, instance)
        end
      end
      time_taken = Time.now.to_i - start
      @logger.info("Completed model #{@klass.to_s} in #{time_taken} secs")
    end

    # Update the maps with the given instance.  If the instance has
    # changed, remove the old data from the maps.
    def update_instance(instance)
      locked_modify(@key) do |map|
        remove_stale_instance(map, instance)
        add_instance(map, instance)
      end
    end

    # Remove the given instance from the maps.
    def remove_instance(instance)
      locked_modify(@key) do |map|
        remove_stale_instance(map, instance)
      end
    end

    private

    def cache
      MEMCACHE
    end

    def add_instance(map, instance, type='device')
      g = instance.map_to_grid
      c = instance.map_to_cluster
      h = instance.map_to_host
      map[g] ||= {}
      map[g][c] ||= {}
      map[g][c][h] = "#{type}:#{instance.device_id}" unless h.nil?
    end

    # Remove stale instance from the interchange map.  Either because the
    # instance has been updated or because it has been deleted.
    #
    # If the instance has been deleted call without +changes+.  If the
    # instance has been updated call with changes set to
    # +instance.previous_changes+.
    def remove_stale_instance(map, instance)
      g = instance.map_to_grid_previously_was || instance.map_to_grid
      c = instance.map_to_cluster_previously_was || instance.map_to_cluster
      h = instance.map_to_host_previously_was || instance.map_to_host

      grid = map[g] ||= {}
      cluster = grid[c] ||= {}
      cluster.delete(h)
      grid.delete(c) if cluster.empty?
      map.delete(g) if grid.empty?
    end
  end

  extend ActiveSupport::Concern

  included do
    after_save :update_interchange
    after_destroy :remove_from_interchange
  end

  class_methods do
    # Store all instances in the interchange.
    def preheat_interchange
      interchange_repo.store_instances(all)
    end

    # Return the interchange repo.
    #
    # The repo defines how instances are stored in the interchange.
    def interchange_repo
      @_interchange_repo ||= Repo.new
    end
  end

  # +update_interchange+ stores the updated (or new) instance in the
  # interchange.
  def update_interchange
    self.class.interchange_repo.update_instance(self)
  end

  # +remove_from_interchange+ removes the instance in the interchange.
  def remove_from_interchange
    self.class.interchange_repo.remove_instance(self)
  end
end
