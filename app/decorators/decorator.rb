#
# Base decorator class
#
class Decorator

  # subject   - the thing being decorated
  # opts      - hash of options
  def initialize(subject, opts = {})
    @subject      = subject
    @opts         = opts
  end

  def decorate!
    decorate_subject!
    @subject
  end

  def self.decorate!(subject, opts = {})
    decorator = new(subject, opts)
    decorator.decorate!
  end

  protected

  attr_reader :opts

  # This is the method you need to override when you create a new decorator.
  def decorate_subject!
    raise NotImplementedError
  end
end
