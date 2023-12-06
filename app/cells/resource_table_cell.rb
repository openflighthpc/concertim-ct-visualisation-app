#
# ResourceTableCell
#
# For displaying resource tables, which are typically the ones you see on index pages.  
#
# Usage:
#
#   render_resource_table_for @users, :option => "foo" do |t|
#     t.attribute_column :name
#   end
#

class ResourceTableCell < Cell::ViewModel
  include Pagy::Frontend

  delegate :sort_column, :sort_direction, to: :controller

  def show(items, opts = {}, block)
    Builder.new(self, items, controller, opts).tap do |builder|
      block.call(builder)
      @table = builder.table
    end

    if items.blank?
      return render view: :empty_table
    else
      return render view: :show
    end
  end

  private

  def controller
    context[:controller]
  end

  #
  # Builder
  #
  # A builder class that builds resource tables - this is yielded to the view
  # allowing users to call methods that add columns to the table etc.
  #
  class Builder

    attr_reader :table

    def initialize(table_cell, items, controller, opts)
      @table_cell = table_cell
      @table = ResourceTable.new(opts.delete(:table_id), items, controller, opts)
    end

    #
    # attribute column
    #
    # A column which will call a method on the item it's being evaluated for. The
    # resultant table cell will then contain the result of calling that method. Typically
    # these are used for attrbites.
    #
    # Passing a block to this method yields the item itself and the result.
    #
    def attribute_column(method, opts = {}, &block)
      add_column AttributeColumn.new(method, opts, &block), opts
    end

    def custom_column(title, opts = {}, &block)
      add_column CustomColumn.new(title, opts, &block), opts
    end

    def select_all_column(opts = {}, &block)
      add_column SelectAllColumn.new(opts, &block), opts
    end

    def actions_column(opts={}, &block)
      add_column ActionsColumn.new(@table_cell, opts, &block), opts
    end

    #
    # on_empty_collection takes a block to render when the table is empty,
    # i.e., when the passed `items` is empty.
    #
    def on_empty_collection(&block)
      @table.empty_collection_block = block
    end

    private 

    def add_column(column, opts)
      return if opts[:suppress_if]

      if column.is_a?(ActionsColumn)
        @table.actions_column = column
      else
        @table.columns << column
      end
    end
  end


  #
  # ResourceTable
  #
  # A model representing the actual table itself. 
  #
  # Attributes of note: 
  #
  #   => @id              The html id of the table
  #   => @items           The items being rendered by the table
  #   => @opts            Any options passed to the table
  #   => @columns         The columns for the table
  #   => @actions_column  The actions-column for the table
  #
  #
  class ResourceTable
    attr_reader :columns,
      :default_db_table,
      :id,
      :items,
      :opts,
      :pagy

    attr_accessor :actions_column

    def initialize(id, items, controller, opts = {})
      @id = id
      @items = items
      @opts = opts
      @columns = Array.new
      @actions_column = nil
      @controller = controller

      establish_if_paginatable
      example_item = items.first if items
      if(example_item)
        determine_db_table(example_item)
      end
    end
    
    def empty?
      @items.empty?
    end

    def has_actions?
      !!@actions_column
    end

    def searchable?
      !!opts[:searchable]
    end

    def paginatable?
      @paginatable
    end

    def empty_collection_block=(block)
      @empty_collection_block = block
    end

    def render_as_empty
      if @empty_collection_block
        return @empty_collection_block.call
      end
      nil
    end

    private

    def determine_db_table(item_example)
      if item_example.class.respond_to? :table_name
        @default_db_table = item_example.class.table_name
      end
    end

    def establish_if_paginatable
      if @controller.respond_to?(:get_pagy) && @controller.get_pagy.is_a?(::Pagy)
        @pagy = @controller.get_pagy
        @paginatable = true
      end
    end
  end


  #
  # Column
  # 
  # Base class for all types of column that could be added to the table. 
  #
  class Column
    include ActionView::Helpers::TagHelper

    attr_reader :title, :tooltip

    def initialize(title, opts = {}, &block)
      @title = opts.delete(:title) || title
      @tooltip = opts.delete(:tooltip)
      @html_class = opts.delete(:class)
      @opts = opts
      @block = block if block_given?
      @overridden_db_column  = opts[:db_column]      # For sorting, must be specified for sortable non-attribute columns
  end


    #
    # html_class
    #
    # The html classes to use for this column, will be applied to both TH and TD elements of the column.
    #
    def html_class(index = nil)
      html_classes = []
      html_classes << :first if index.zero?
      html_classes << @html_class
      html_classes
    end


    #
    # render_content_for
    #
    # Simple accessor for the row/column's content. This *may* become more complex over time, for
    # example if someone asks for all dates in tables to look a certain way, this is where you 
    # would make this change in order to keep that logic out of the view.
    #
    def render_content_for(item)
      item.to_s
    end

    def sortable?
      @opts[:sortable] == true
    end   

    # If this table is sortable, this yields the data required to render the sortable header that the
    # user clicks on.  The `yield`ed values are:
    #
    # * the name of the sort column for sorting this column.
    # * the direction for sorting this column.  This will be "asc" unless this
    # column is already sorted in ascending order.
    # * whether this column is currently sorted.
    def sortable_header(current_sort_column, current_sort_direction)
      sort_expression = sort_column.to_s
      is_current      = sort_expression == current_sort_column
      sort_order      = (is_current && current_sort_direction == "asc") ? "desc" : "asc" 

      yield sort_expression, sort_order, is_current 
    end

    # Will either be the method name (in the case of attribute columns) or will be
    # the overridden one passed into the column using the :db_column option.
    def sort_column
      @overridden_db_column || @method
    end

    def select_all_column?
      kind_of? SelectAllColumn
    end
  end


  #
  # CustomColumn
  # 
  # This is a basic column type that just yields the item back to the view.
  #
  class CustomColumn < Column

    def initialize(title, opts, &block)
      super(title.to_s, opts, &block)
    end

    def render_content_for(item)
      if @block
        @block.call item
      else
        item.to_s
      end
    end
  end


  #
  # AttributeColumn
  # 
  # This column type will call a given method on the item, and then yield the
  # result of that method as well as the item back to the view.
  #
  class AttributeColumn < Column

    def initialize(method, opts, &block)
      @method = method
      super(method.to_s.titleize, opts, &block)
    end

    def render_content_for(item)
      begin
        if @block
          @block.call item, item.send(@method)
        else
          item.send(@method) 
        end
      rescue Exception => e
        raise "Tried to call method '#{@method}' on #{item}: #{e.message}"
      end
    end
  end

  #
  # SelectAllColumn
  #
  # Renders a "select all" column to the view, yielding the item.
  # 
  class SelectAllColumn < Column

    def initialize(opts, &block)
      super(opts[:title] || "Select All", opts, &block)
    end

    def render_content_for(item)
      if @block
        @block.call item
      else
        item.to_s
      end
    end
  end

  # Renders an "actions column", which is a column containing a dropdrown which
  # in turn contains various actions to perform on the current row.  Typical
  # actions include navigating to the resource's edit page, or deleting the
  # resource.
  #
  # When an actions column is added to a resource table, a
  # ActionsCell::ActionBuilder and the item for the current row are yielded.
  # The builder defines an API for adding actions.
  #
  # Usage:
  #
  #   render_resource_table_for @users do |t|
  #     t.actions_column do |actions, user|
  #       actions.add 'View', user_path(user)
  #       actions.add_with_auth title: 'Edit', path: edit_user_path(user), can: :edit, on: user
  #     end
  #   end
  #
  class ActionsColumn < Column
    def initialize(table_cell, opts={}, &block)
      @table_cell = table_cell
      @opts = opts
      @block = block
    end

    def render_content_for(item)
      block = ->(builder) { @block.call(builder, item) }
      dropdown_id = item.respond_to?(:to_gid_param) ? item.to_gid_param : item.id
      opts = @opts.merge(is_dropdown: true, dropdown_id: dropdown_id)
      @table_cell.cell(:actions).(:show, 'Actions', block, opts)
    end
  end
end
