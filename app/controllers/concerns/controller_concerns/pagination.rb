#
# Controller Mixin for methods pertaining to pagination.
#
module ControllerConcerns
  module Pagination
    extend ActiveSupport::Concern

    included do
      include Pagy::Backend
    end

    def get_pagy
      @pagy
    end
  end
end
