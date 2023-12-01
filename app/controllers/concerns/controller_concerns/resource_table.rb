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
      # include ControllerConcerns::Pagination
      # include ControllerConcerns::Sorting
    end

    # A convinience method allowing you to pass in a collection (typically an
    # Activercord::Relation, but you can also pass arrays). It passes this
    # collection on to a decorator class that wires it up with
    # sort/search/pagination functionality and returns the resultant
    # colleciton.
    def resource_table_collection(collection, opts = {})
      ResourceTableCollectionDecorator.decorate!(collection, opts.merge(controller: self))
    end
  end
end
