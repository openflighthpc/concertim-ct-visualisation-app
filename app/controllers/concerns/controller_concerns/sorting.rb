# 
# Controller Mixin for methods pertaining to sorting. 
#

module ControllerConcerns
  module Sorting
    extend ActiveSupport::Concern

    included do
      helper_method :active_sort_column, :sort_column, :sort_direction
    end

    # Override this method in the controller to change the default sort column.
    def default_sort_column
      "id"
    end

    def sort_column
      params[:sort] || default_sort_column.to_s || "id"
    end

    # Returns the sort direction indicated by the http parameters defaulting to "asc".
    def sort_direction
      %w( asc desc ).include?(params[:direction]) ? params[:direction] : "asc"
    end


    # Returns an active record sort expression from the column/direction passed in
    #
    # If the human_sorting parameter is true, it will sort them alphanumerically using a SORT BY of 2 arguments 
    # - 1st argument will be ALL (and I mean ALL) the letters of the column
    # - 2nd argument will be ALL (and I mean ALL) the numbers of the column
    def sort_expression(column, direction = 'asc', human_sorting = 'false')
      unless %w(asc desc).include?(direction.downcase)
        raise ArgumentError, "unsupported direction #{direction}"
      end
      quoted_column = ApplicationRecord.connection.quote_column_name(column)
      if human_sorting == 'true'
        "regexp_replace(#{quoted_column}, '[^a-zA-Z]', '', 'g') #{direction}, NULLIF(regexp_replace(#{quoted_column}, E'\\\\D','','g'), '')::bigint #{direction}" 
      else
        "#{quoted_column} #{direction}"
      end
    end


    private

    # Returns the name of the currently asked-for sort column based on the 
    # http parameters. Massages result prior to returning, so:
    #
    # User.name becomes "name"
    def active_sort_column(parent_table, default_column = "id")
      associated_table, column_name = massage_sortable_table_params(params[:sort])
      table = associated_table.nil? ? parent_table.pluralize : associated_table.pluralize
      table_object = table.classify.constantize
      table_object.column_names.include?(column_name) ? column_name : default_column
    end

    # Receives a table name and a column name in string format with a seperator
    # and batters it into a 2d array, where index[0] represents the table name and 
    # index[1] represents the column.
    def massage_sortable_table_params(table_column)
      seperator = /__|\./
      unless table_column.nil?
        table_column =~ seperator ? table_column.split(seperator) : [nil, table_column]
      end
    end
  end
end