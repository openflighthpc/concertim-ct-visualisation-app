#
# ControllerConcerns::Search
#
# Controller mixin for methods pertaining to search.
#
module ControllerConcerns
  module Search
    extend ActiveSupport::Concern

    included do
      helper_method :search_term
    end

    def search_term
      params[:search]&.strip
    end
  end
end
