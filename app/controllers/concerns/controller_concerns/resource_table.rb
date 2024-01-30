#
# ControllerConcerns::ResourceTable
#
# Resource Tables are the tables typically used in index actions which display
# a collection which is:
# 
# * paginatable
# * sortable
# * searchable 
# 
# This concern includes the three concerns that manage these operations, as well as providing a 
# convinience method which performs all the actions upon a given collection.
#
module ControllerConcerns
  module ResourceTable
    extend ActiveSupport::Concern

    included do
      include ControllerConcerns::Search
      include ControllerConcerns::Pagination
      include ControllerConcerns::Sorting
    end

    # Prepare the collection for use in a resource table.
    #
    # This will sort, search and paginate the collection.
    def resource_table_collection(collection, human_sorting: false, search_scope: nil, model: nil)
      return [] if collection.nil?

      if collection.respond_to?(:reorder)
        exp = sort_expression(sort_column, sort_direction, human_sorting, model)
        collection = collection.reorder(Arel.sql(exp))
      end

      if collection.respond_to?(:ancestors) && collection.ancestors.include?(Searchable)
        collection = collection.search_for(search_term, search_scope: search_scope)
      end

      if respond_to?(:pagy, true)
        @pagy, collection = pagy(collection)
      end

      collection
    end
  end
end
