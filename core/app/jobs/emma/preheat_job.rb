module Emma
  class PreheatJob < ApplicationJob
    queue_as :default

    def perform(mod)
      preheater = mod::Interchange::Preheater
      preheater.safely_preheat(mod)
    end
  end
end
