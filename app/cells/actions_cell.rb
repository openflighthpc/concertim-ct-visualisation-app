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

  def show(text, block, opts = {})
    # @text = text
    @is_dropdown = opts[:is_dropdown] || false
    @dropdown_id = opts[:dropdown_id] || 'drop'
    @side = opts[:side] || false

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

  def side?
    !!@side
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
    # Adds an action based on options hash. Valid options are: text, path, html, side
    #
    # 'side' == true will render to the sidebar only.
    #
    # Any other options are treated as html attributes
    #
    # e.g:
    #
    # add(text: 'View', path: user_path(@user))
    # # => <li><a href="/users/2">View</a></li>
    #
    def add(text_or_options, path = nil, &block)
      if text_or_options.kind_of? String
        options = {}
        text = text_or_options
      else
        options = text_or_options
        text = options[:text]
        path = options[:path]
      end

      html = (block_given? ? block.call : options[:html])
      opts = options.reject {|k, v| [:text, :html, :path, :can, :cannot, :on].include?(k)}

      if html
        add_custom(html, opts)
      else
        add_item(text, path, opts)
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
      ability = @current_user.ability

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
    # Adds a label with content that separates menu items.
    #
    def divider(text = nil)
      unless @dropdown_actions.empty?
        divider = ActionDivider.new(text)
        @dropdown_actions << divider
      end
    end

    private

    def side?
      @cell.side?
    end

    #
    # add_item
    #
    # Adds a basic link action
    #
    def add_item(text, path, opts = {})
      action = Action.new(text, path, opts, @cell)
      if side?
        @actions << action
      else
        @dropdown_actions << action
      end
    end

    #
    # add_custom
    #
    # when you want to specify the html in the view rather
    # than have it worked out here.
    #
    def add_custom(html, opts = {})
      action = CustomAction.new(html, opts)
      if side?
        @actions << action
      else
        @dropdown_actions << action
      end
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
    attr_reader :text, :path, :opts
    def initialize(text, path, opts = {}, cell)
      @text = text
      @path = path
      @opts = opts
      @cell = cell
    end

    def html
      @cell.link_to @text, @path, @opts
    end
  end

  class ActionDivider < ActionItem
    attr_reader :text

    def initialize(text)
      @text = text
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
end
