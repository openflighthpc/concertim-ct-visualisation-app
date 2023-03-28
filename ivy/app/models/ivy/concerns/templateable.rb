module Ivy
  module Concerns
    #
    # Templateable encapsulates common logic around resources which have a template.
    #
    # A template represents data about some piece of hardware.  It has
    # attributes such as, manufacturer, model, height, depth, image URL etc..
    #
    # Racks and chassis have templates; devices delegate to their chassis's
    # template.
    #
    module Templateable
      
      extend ActiveSupport::Concern
      
      included do
        belongs_to :template

        delegate :manufacturer, :model,
          to: :template, allow_nil: true
      end
      
    end
  end
end
