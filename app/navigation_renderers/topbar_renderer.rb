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
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

#
# TopBar renderer.
#
# Custom foundation5 topbar renderer for SimpleNavigation. A reference to this 
# class is included on the main application layout file, allowing this to take
# over the rendering as per the simplenavigation guides. 
#
# See https://github.com/codeplant/simple-navigation/wiki/Custom-renderers
#
# Actual nav is specified in app/config/navigation.rb
#
class TopbarRenderer < SimpleNavigation::Renderer::Base

  #
  # Main entry point for rendering top bar.
  #
  def render(item_container)
    left_menu = []
    right_menu = []

    item_container.items.each do |menu_item|
      if menu_item.options.delete(:align) == :right
        right_menu << menu_item
      else
        left_menu << menu_item
      end
    end

    left_list_items   = generate_list_items_for(left_menu, item_container.level)
    right_list_items  = generate_list_items_for(right_menu, item_container.level)

    "#{ render_list_content_for(left_list_items, item_container, :left) }
     #{ render_list_content_for(right_list_items, item_container, :right) }".html_safe
  end


  private

  #
  # generate_list_items_for(items, item_level)
  #
  # Accepts a list of menu items and generates a block of html list items
  # representing the menu items.
  #
  def generate_list_items_for(items, item_level)
    item_list = []

    items.each do |item|
      li_options = item.html_options.reject {|k, v| k == :link || k == :icon}
      link_options = item.html_options[:link]

      li_content = generate_tag_for(item, item_level)

      if include_sub_navigation?(item)
        next if item.sub_navigation.items.count == 0
        li_options[:class] = "#{li_options[:class]} has-dropdown"
        li_content << render_sub_navigation_for(item)
      end

      item_list << content_tag(:li, li_content, li_options) 
    end
      
    item_list.join
  end


  #
  # render_list_content_for
  #
  # Renders the containing ul for the list items (<li>) in the 
  # nav.
  #
  def render_list_content_for(list_items, item_container, alignment = :left)
    content_tag(:ul, list_items, {:id => item_container.dom_id, 
            :class => [alignment, item_container.level > 1 ? :dropdown : item_container.dom_class]})
  end


  #
  # generate_tag_for
  #
  # Generate the actual tag that goes inside a list item (li). This will 
  # typically just be a link with an accompanying icon.
  #
  def generate_tag_for(item, item_level)
    if suppress_link?(item)
      content_tag('span', item.name, link_options_for(item).except(:method))
    else
      link_to(icon_for(item, item_level) + " " + item.name, item.url, options_for(item))
    end
  end


  #
  # icon_for
  #
  # Generates a span for the list item's icon, e.g. 
  #
  # <span class="icon-info"></span>
  #
  def icon_for(item, item_level)
    css_class = "icon-#{item.options[:icon]}" unless item_level > 2
    content_tag(:span, nil, class: css_class)
  end
end
