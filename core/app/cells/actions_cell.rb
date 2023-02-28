#
# ActionsCell
#
# For displaying actions dropdown at top right of the page.
#
# Usage:
#
#   render_actions_dropdown 'Data Centre Actions' do |actions|
#     actions.add 'View Data Centre', clusters_path
#     actions.add 'Edit Data Centre', edit_clusters_path
#   end
#
# NB: #render_actions_dropdown is a helper method.
#   
class ActionsCell < Cell::ViewModel
  include Devise::Controllers::Helpers

  attr_reader :actions, :dropdown_id

  def show(title, block, opts = {})
    # @title = title
    @is_dropdown = opts[:is_dropdown] || false
    @dropdown_id = opts[:dropdown_id] || 'drop'

    ActionBuilder.new(current_user, self).tap do |builder|
      block.call(builder)
      @actions = @is_dropdown ? builder.dropdown_actions : builder.actions
    end

    template = @is_dropdown ? :dropdown_actions : :side_actions
    render view: template
  end

  def li_attrs(action)
    attrs =
      if action.matches_request?(request)
        { class: 'current' }
      else
        {}
      end
    attrs.merge(action.li_opts)
  end

  def ul_attrs
    if @is_dropdown
      @ul_attrs = {id: @dropdown_id, class: ['f-dropdown', 'content'], "data-dropdown-content": ""}
    else
      @ul_attrs = {:class => ['menublock']}
    end
  end

  def div_attrs
    if @is_dropdown
      { class: :dropdown_actions }
    else
      {}
    end
  end

  private

  class ActionBuilder
    attr_reader :actions, :dropdown_actions, :subject

    def initialize(current_user, cell)
      @actions = Array.new
      @dropdown_actions = Array.new
      @current_user = current_user
      @cell = cell
    end
    
    #
    # add
    #
    # Adds an action based on options hash. Valid options are: title, path, html, side
    #
    # 'side' == true will render to the sidebar only.
    #
    # Any other options are treated as html attributes
    #
    # e.g:
    #
    # add(title: 'View', path: user_path(@user))
    # # => <li><a href="/users/2">View</a></li>
    #
    def add(title_or_options, path = nil, &block)
      if title_or_options.kind_of? String
        options = {}
        title = title_or_options
      else
        options = title_or_options
        title = options[:title]
        path = options[:path]
      end

      html = (block_given? ? block.call : options[:html])
      opts = options.reject {|k, v| [:title, :html, :path, :can, :cannot, :on].include?(k)}
      
      if opts[:side]
        add_side(html, opts)
      elsif html
        add_custom(html, opts)
      else
        add_item(title, path, opts)
      end
    end

    def add_with_auth(options, &block)
      resource_or_class = options[:on]
      
      if options.has_key? :cannot
        action_name = options[:cannot]
        permission = :cannot?
      elsif options.has_key? :can
        action_name = options[:can]
        permission = :can?
      end
    
      opts = options.reject {|k, v| [:can, :cannot, :on].include?(k)}

      @ability_manager ||= Emma::CanCanAbilityManager.new(@current_user)
      ability = @ability_manager.ability_for(resource_or_class)
      
      if ability.send(permission, action_name, resource_or_class)
        if block_given?
          add(opts, &block)
        else
          add(opts)
        end
      end
    end
    
    #
    # divider
    #
    # Adds a label with a title that separates menu items.
    #
    def divider(title = nil)
      unless @actions.empty?
        divider = ActionDivider.new(title)
        @dropdown_actions << divider
      end
    end
 
    private
  
    #
    # add_item
    #
    # Adds a basic link action
    #
    def add_item(title, path, opts = {})
      action = Action.new(title, path, opts, @cell)
      @dropdown_actions << action
    end

    #
    # add_custom
    #
    # when you want to specify the html in the view rather
    # than have it worked out here.
    #
    def add_custom(html, opts = {})
      action = CustomAction.new(html, opts)
      @dropdown_actions << action
    end

    #
    # add_side
    # 
    # Used to specify html that will be rendered in the sidebar only.
    #
    def add_side(html, opts = {})
      action = SideAction.new(html, opts)
      @actions << action
    end
 end
  
  class ActionItem
    def li_opts
      @opts.reject {|k, v| [:path, :side, :method, :confirm].include?(k) }
    end
    
    def matches_request?(request)
      request.fullpath == @path unless @opts[:method].to_s == 'delete'
    end

    def divider?
      false
    end
  end

  class Action < ActionItem
    attr_reader :title, :path, :opts
    def initialize(title, path, opts = {}, cell)
      @title = title
      @path = path
      @opts = opts
      @cell = cell
    end

    def html
      @cell.link_to @title, @path, @tops
    end
  end

  class ActionDivider < ActionItem
    attr_reader :title

    def initialize(title)
      @title = title
      @path = nil
      @opts = {}
    end

    def divider?
      true
    end
  end

  class CustomAction < ActionItem
    attr_reader :html, :path, :opts

    def initialize(html, opts = {})
      @html = html
      @path = opts[:path]
      @opts = opts
    end
  end

  class SideAction < ActionItem
    attr_reader :html, :opts

    def initialize(html, opts = {})
      @html = html
      @path = nil
      @opts = opts
    end
  end
end
