class PreheatJob < ApplicationJob
  queue_as :default

  def perform(mod=nil)
    preheater = mod ? mod::Interchange::Preheater : Interchange::Preheater
    preheater.safely_preheat(mod)
  end
end
