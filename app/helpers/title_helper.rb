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

module TitleHelper

  #
  # set_title sets the content for the :page_title page section, which is used
  # both as a heading (h2) on all pages as well as the actual <title> meta tag.
  #
  def set_title(title)
    content_for :title do
      title
    end
  end

  def title_css_classes
    css_classes = []
    icon = icon_name
    css_classes << "icon-#{icon.to_s.parameterize}" unless icon.blank?
    css_classes << (active_navigation_item_key || inferred_heading)

    css_classes.join(' ')
  end

  def icon_name
    return @icon_override if @icon_override
    if active_navigation_item && active_navigation_item.options.nil?
      controller_name.singularize
    else
      curr_item = active_navigation_item
      if curr_item && !curr_item.options.nil? && !curr_item.options[:icon].blank?
        curr_item.options[:icon]
      else
        level2_item = active_navigation_item(:level => 2)
        (level2_item ? level2_item.options[:icon] || inferred_heading : inferred_heading)
      end
    end
  end

  def inferred_heading
    "#{params[:controller].split('/').last}_#{params[:action]}"
  end

  #
  # sanitize_title removes anchors and other tags from a string (so they can be
  # used for page titles)
  #
  # XXX Does rails provide a better mechanism for this than using regexes.
  #
  def sanitize_title(title)
    title.gsub!(/<\/?a[^>]*>/, "")
    title.gsub!(/<\/?[^>]*>/, '"')
    raw title
  end

end
