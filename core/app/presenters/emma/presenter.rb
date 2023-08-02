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

  # Is there a better place for this?
  module Costed
    extend ActiveSupport::Concern

    def formatted_cost
      "$#{'%.2f' % cost}"
    end
  end
end
