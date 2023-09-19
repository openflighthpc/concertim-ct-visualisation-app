class Facade

  def initialize(object)
    @object = object
  end

  protected

  def o
    @object
  end

end
