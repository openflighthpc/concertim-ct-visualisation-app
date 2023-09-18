#
# Base presenter class
# 
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

module Costed
  extend ActiveSupport::Concern

  def cost
    "$#{'%.2f' % o.cost}"
  end
end