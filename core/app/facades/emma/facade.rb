#
# Emma::Facade
#
# Base facade class for emma
# 
module Emma
  class Facade

    def initialize(object)
      @object = object
    end

    protected

    def o
      @object
    end

  end
end
