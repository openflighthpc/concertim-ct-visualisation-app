#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

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
