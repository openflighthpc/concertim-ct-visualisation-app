module Ivy
  module Concerns
    module DataSourceMap
      #
      # Functionality for storing DataSourceMap's in the interchange.  It's
      # extracted here just to group it all togther.
      #
      module Interchange

        # Maintains to maps. One from device id to map to host and the other
        # from map to host to device id.  The serialization of these two maps
        # is what is stored in the interchange.
        class Repo
          include Phoenix::Cache::Locking

          def initialize
            @forward_map_key = "hacor:data_source_map"
            @reverse_map_key = "hacor:reverse_data_source_map"
          end

          # Updates the two maps with the given instances.
          def store_instances(instances)
            locked_modify(@forward_map_key) do |map|
              instances.each do |instance|
                add_instance_to_map(map, instance)
              end
            end
            locked_modify(@reverse_map_key) do |map|
              instances.each do |instance|
                add_instance_to_reverse_map(map, instance)
              end
            end
          end

          # Update the maps with the given instance.  If the instance has
          # changed, remove the old data from the maps.
          def update_instance(instance)
            locked_modify(@forward_map_key) do |map|
              remove_old_instance_from_map(map, instance, instance.previous_changes)
              add_instance_to_map(map, instance)
            end
            locked_modify(@reverse_map_key) do |map|
              remove_old_instance_from_reverse_map(map, instance)
              add_instance_to_reverse_map(map, instance)
            end
          end

          # Remove the given instance from the maps.
          def remove_instance(instance)
            locked_modify(@forward_map_key) do |map|
              remove_old_instance_from_map(map, instance)
            end
            locked_modify(@reverse_map_key) do |map|
              remove_old_instance_from_reverse_map(map, instance)
            end
          end

          private

          def cache
            MEMCACHE
          end

          def add_instance_to_map(map, instance, type='device')
            g = instance.map_to_grid
            c = instance.map_to_cluster
            h = instance.map_to_host
            map[g] ||= {}
            map[g][c] ||= {}
            map[g][c][h] = "hacor:#{type}:#{instance.device_id}" unless h.nil?
          end

          def add_instance_to_reverse_map(map, instance, type='device')
            key = "hacor:#{type}:#{instance.device_id}"
            # map[key] = [instance.map_to_grid, instance.map_to_cluster, instance.map_to_host]
            map[key] = instance.map_to_host
          end

          # Remove an instance from the interchange map.
          #
          # If the instance has been deleted call without +changes+.  If the
          # instance has been updated call with changes set to
          # +instance.previous_changes+.
          def remove_old_instance_from_map(map, instance, changes={})
            g = changes.key?(:map_to_grid) ? changes[:map_to_grid] : instance.map_to_grid
            c = changes.key?(:map_to_cluster) ? changes[:map_to_cluster] : instance.map_to_cluster
            h = changes.key?(:map_to_host) ? changes[:map_to_host] : instance.map_to_host

            grid = map[g] ||= {}
            cluster = grid[c] ||= {}
            cluster.delete(h)
            grid.delete(c) if cluster.empty?
            map.delete(g) if grid.empty?
          end

          def remove_old_instance_from_reverse_map(map, instance, type='device')
            key = "hacor:#{type}:#{instance.device_id}"
            map.delete(key)
          end

        end

        extend ActiveSupport::Concern

        included do
          after_save :update_interchange
          after_destroy :remove_from_interchange
        end

        class_methods do
          def interchange_repo
            @_interchange_repo ||= Repo.new
          end

          def preheat_interchange
            interchange_repo.store_instances(all)
          end
        end

        def update_interchange
          self.class.interchange_repo.update_instance(self)
        end

        def remove_from_interchange
          self.class.interchange_repo.remove_instance(self)
        end
      end
    end
  end
end
