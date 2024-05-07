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

# DefinitionListCell is used to render definition lists.
#
# Usage:
#
#   definition_list "Details" do |dl|
#     # Render a single item.
#     dl.item "Name:", device.name
#
#     # The content can be passed as the second argument or as a block.
#     dl.item "Description:" do
#       capture do
#         concat device.description
#         concat content_tag(:em, '!!!')
#       end
#     end
#
#     # Render a sub-definintion list.  This will create a item "Access details"
#     # under which there will be a nested definition list containing the items
#     # "Login user" and "Public IP".
#     dl.sublist "Access details:" do |sl|
#       sl.item "Login user:", device.login_user
#       sl.item "Public IP:", device.public_ip
#
#     # Recurse into the given data structure rendering nested lists for any
#     # encountered arrays and hashes.  Other items are rendered as single values
#     # using their `to_s` method.
#     dl.recurse_items "Metadata", device.metadata
#
# NB: definition_list is a helper method.
class DefinitionListCell < Cell::ViewModel
  def show(title, block, opts = {})
    @title = title

    ItemBuilder.new.tap do |builder|
      block.call(builder)
      @items = builder.items
    end

    if @items.empty?
      nil
    else
      render
    end
  end

  def render_item(item)
    return unless item.show?

    if item.is_a?(Item)
      render view: :item, locals: { item: item }
    elsif item.is_a?(Sublist)
      render view: :sublist, locals: { sublist: item }
    end
  end

  class ItemBuilder
    def initialize
      @items = []
    end

    # Add a single item.
    def item(title, content_or_options_with_block=nil, opts=nil, html_opts=nil, &block)
      if block_given?
        html_opts = opts || {}
        if content_or_options_with_block.is_a?(Hash)
          opts = content_or_options_with_block
        else
          opts = {}
        end
        content = block.call
      else
        content = content_or_options_with_block
        opts = opts || {}
        html_opts = html_opts || {}
      end
      @items << Item.new(title, content, opts, html_opts)
    end

    # Start a sub definition list.  Items can be added to it identically to the
    # main definition list.
    def sublist(title, opts = {}, &block)
      builder = ItemBuilder.new
      block.call(builder)
      subitems = builder.items
      @items << Sublist.new(title, subitems, opts)
    end

    # Recurse down the given data structure.  Each encountered array or hash
    # will be recursively rendered as a new sublist.  Other items will be
    # rendered as single value using the `.to_s` method.
    def recurse_items(title, data)
      if data.is_a?(Hash)
        sublist(title) do |subbuilder|
          data.each do |key, val|
            subbuilder.recurse_items(key, val)
          end
        end
      elsif data.is_a?(Array)
        sublist(title) do |subbuilder|
          data.each_with_index do |val, i|
            subbuilder.recurse_items(i, val)
          end
        end
      else
        item(title, data)
      end
    end

    def items
      @items.select { |item| item.show? } if @items
    end
  end

  class Item
    attr_reader :title, :opts, :html_opts

    def initialize(title, content, opts, html_opts)
      @title = title
      @content = content
      @opts = opts
      @html_opts = html_opts
    end

    def show?
      @content.present? || !!opts[:always_show]
    end

    def content
      if @content.is_a?(Date)
        @content.strftime(opts[:date_format] || '%d/%m/%Y')
      else
        @content
      end
    end
  end

  class Sublist
    attr_reader :title, :items

    def initialize(title, items, opts)
      @title = title
      @items = items
      @opts = opts
    end

    def show?
      @items.any?(&:show?)
    end
  end
end
