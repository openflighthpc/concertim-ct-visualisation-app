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

require 'pagy'

class Pagy
  # A custom Pagy class to help generate pagination links for HTTP API
  # responses.
  #
  # Typically, an HTTP API response will provide a count of the total items along
  # with the request for items.  This Pagy class makes it easier to consume
  # such APIs without an additional HTTP call just to retrieve the count of
  # items.
  #
  # Suppose an API (1) already paginates its responses; and (2) only provides
  # the total number of items after we've requested some.  Suppose also we want
  # to display a page of items complete with pagination controls.  Suppose
  # further we want this to be consistent with our existing use of Pagy.
  #
  # There are three parts that we want Pagy to handle.
  #
  # 1. Determining the offset and limit in a manner consistent with our
  #    existing use of Pagy.
  # 2. Rendering the appropariate pagination links in a manner consistent with
  #    our existing use of Pagy.
  # 3. Handling overflow and other variable errors in a manner consitent with
  #    our existing use of Pagy.
  #
  # This custom Pagy class does just that.
  #
  # The usage of this Pagy class can be broken down into three parts:
  #
  # First we generate a Pagy::DelayedCount instance so that we can interrogate
  # it for the offset, etc..  Doing this ensures that handling and request
  # params, defaults and variable errors is consistent with our other usage of
  # Pagy.
  #
  #     @pagy = Pagy::DelayedCount.new(pagy_get_vars_without_count)
  #
  # Next we make an API call using the determined offset and limit.  The result
  # of the API call needs to make available, both the pre-paginated collection
  # and the total number of items.
  #
  #     @collection, total_items = make_api_call(offset: pagy.offset, limit: pagy.items)
  #
  # Finally, we finalize the @pagy instance with the now available total count
  # of items.
  #
  #     @pagy.finalize(total_items)
  #
  # This @pagy instance and @collection can now be used exactly as for any
  # other pagy usage.
  class DelayedCount < Pagy
    # Merge and validate the options, do some simple arithmetic and set the instance variables
    def initialize(vars) # rubocop:disable Lint/MissingSuper
      normalize_vars(vars)
      setup_vars(page: 1, outset: 0)
      setup_items_var
      setup_offset_var
      setup_params_var
      setup_request_path_var
    end

    # Finalize the instance variables based on the now available count.
    def finalize(count)
      raise VariableError.new(self, :count, "to be >= 0", count) \
        unless count&.respond_to?(:to_i) && count.to_i >= 0
      @count = count.to_i
      setup_pages_var
      raise OverflowError.new(self, :page, "in 1..#{@last}", @page) if @page > @last

      @from   = [@offset - @outset + 1, @count].min
      @to     = [@offset - @outset + @items, @count].min
      @in     = [@to - @from + 1, @count].min
      @prev   = (@page - 1 unless @page == 1)
      @next   = @page == @last ? (1 if @vars[:cycle]) : @page + 1
      self
    end
  end

  module DelayedCountExtra
    private

    # Similar to pagy_get_vars, but doesn't attempt to determine the count of
    # items.
    def pagy_get_vars_without_count(vars={})
      pagy_set_items_from_params(vars) if defined?(ItemsExtra)
      vars[:page] ||= params[vars[:page_param] || DEFAULT[:page_param]]
      vars
    end
  end

  Backend.prepend DelayedCountExtra
end
