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
# UiHelper
#
# Presently a dumping ground for all things UI related (cells, menus...) this will eventually
# be seperated out into seperate helpers.
#
# * THIS HELPER IS ONLY TEMPORARY
# * NO METHODS IN HERE MORE THAN A FEW LINES LONG
#
module UiHelper

  extend Gem::Deprecate

  # 
  # render_autocomplete_field
  #
  def render_autocomplete_field(field_id, opts = {})
    cell(:autocomplete_field).(:show, field_id, opts)
  end


  #
  # render_lhm_actions renders the actions for the left-hand sidebar menu.
  #
  def render_lhm_actions(title, opts = {}, &block)
    cell(:actions).(:show, title, block, opts.merge(side: true))
  end

  #
  # render_action_dropdown constructs the "Actions" dropdown in the
  # top-righthand corner.
  #
  # See `ActionsCell` and `ActionsCell::ActionBuilder` for more details.
  #
  def render_action_dropdown(title, opts={}, &block)
    content_for :dropdown_actions do
      cell(:actions).(:show, title, block, opts.merge(is_dropdown: true))
    end
  end

  # definition_list renders a <DL> definition list.
  def definition_list(title, opts = {}, &block)
    cell(:definition_list).(:show, title, block, opts)
  end

  # render_tabbar renders a tabbar.  Use render_tab_content to wrap the
  # content for the active tab.
  def render_tabbar(&block)
    cell(:tabbar).(:show, block)
  end

  # render_tab_content renders the given block with suitable layout for
  # use as a tabbar's active content area.  Use render_tabbar to render the
  # tabbar.
  def render_tab_content(&block)
    content_tag :div, class: [:box, :tabContent] do
      yield
    end
  end
end
