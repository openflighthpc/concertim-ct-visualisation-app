#
# Emma::ControllerConcerns::Authentication
#
# Mixin for functionality pertaining to authentication
#
module Emma
  module ControllerConcerns
    module Authentication
      extend ActiveSupport::Concern

      included do
        if respond_to?(:helper_method)
          helper_method :current_user
          helper_method :user_signed_in?
        end
      end

      class_methods do
      end

      def current_user
        Object.new.tap do |o|
          def o.can?(action, resource)
            true
          end
          def o.firstname; 'Mr'; end
          def o.surname; 'Admin'; end
        end
      end

      def user_signed_in?
        true
      end
    end
  end
end
