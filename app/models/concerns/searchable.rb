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
# Searchable
#
# Mixin for models to enable a simple search interface. Include like this:
#
#   class Foo
#     include Searchable
#     default_search_scope :name, :description
#   end
#
# This adds a method to the model class that allows you to pass in a string thusly:
#
#   Foo.search_for "bar"
#   # will return all Foos with "bar" in the name or the description.
#
# All searches will be against the "default search scope" specified in the model 
# using the "default_search_scope" method. If you want to override this, you
# can by passing in your own scope to the "search_for" method like so:
#
#    User.search_for "kate", search_scope: [:name]
#
# This would limit the search scope for this search to ONLY the user's name. You specify
# the scope here in exactly the same format that you specify the default scope.
#
module Searchable
  extend ActiveSupport::Concern

  included do
    scope :search_for, ->(term, search_scope: nil) do 
      return all if term.blank?

      #
      # The default functionality is to use the "default scope" specified on the model using
      # the "default_search_scope" method, however if you pass in a "search_scope" you can
      # override this.
      #
      if search_scope
        perform_search(term, search_scope)
      else
        perform_search(term)
      end
    end
  end

  module ClassMethods
    attr_reader :default_searchable_columns


    # default_search_scope sets the default columns to search.
    def default_search_scope(*columns)
      @default_searchable_columns = columns
    end      


    # Performs a database search on the current model, based on the passed-in parameters.
    #
    #   term         - the search term (such as "A1")
    #   search_scope - the database columns to search 
    #
    # Typically you would not call this directly, it is called from the "scope" defined above.
    #
    def perform_search(term, search_scope = default_searchable_columns)
      quote_column_name = ->(col) { connection.quote_column_name(col) }
      sanitized_term = "%#{sanitize_sql_like(term)}%"

      search_scope.reduce(none) do |accum, column|
        accum.or(where("#{quoted_table_name}.#{quote_column_name.(column)} ILIKE :term", term: sanitized_term))
      end
    end
  end
end
