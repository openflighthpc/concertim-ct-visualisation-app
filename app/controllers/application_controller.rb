class ApplicationController < ActionController::Base
  def current_user
    Object.new.tap do |o|
      def o.can?(action, resource)
        true
      end
    end
  end
  helper_method :current_user
end
