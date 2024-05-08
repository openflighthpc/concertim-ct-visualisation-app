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

# TabbarCell is used to render tab bars.
#
# Usage:
#
# render_tabbar do |tabs|
#   tabs.add 'Overview', device_path(@device) 
#   tabs.add 'Metrics', device_metrics_path(@device)
# end
#
# NB: #render_tabs is a helper method.
#
class TabbarCell < Cell::ViewModel
  def show(block)
    TabsBuilder.new(context).tap do |builder|
      block.call(builder)
      @tabs = builder.tabs
    end

    render 
  end

  private 

  class TabsBuilder
    attr_reader :tabs

    def initialize(context)
      @context = context
      @tabs = []
    end

    def add(title, path, tab_id: nil)
      @tabs << Tab.new(title, path, @context, tab_id: tab_id)
    end
  end

  class Tab
    attr_reader :id, :title, :path

    def initialize(title, path, context, tab_id:nil)
      @id = tab_id || title.parameterize 
      @title = title
      @path = path
      @context = context
    end

    def html_classes
      [].tap do |a|
        a << :active if active?
      end
    end

    def active?
      URI(@context[:controller].request.fullpath).path == @path
    end
  end
end
