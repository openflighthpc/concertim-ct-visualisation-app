#
# Emma::Presenter
#
# Base presenter class for emma
# 
module Emma
  class Presenter

    def initialize(object, view_context = nil)
      @object = object
      @view_context = view_context
    end

    protected

    def o
      @object
    end

    def h
      @view_context
    end

  end
end
