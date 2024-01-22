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
      @context[:controller].request.fullpath.split(/\?/)[0] == @path
    end
  end
end
