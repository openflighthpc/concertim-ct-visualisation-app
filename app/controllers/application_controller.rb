class ApplicationController < ActionController::Base
  def current_user
    Object.new.tap do |o|
      def o.can?(action, resource)
        true
      end
      def o.firstname; 'Mr'; end
      def o.surname; 'Admin'; end
    end
  end
  helper_method :current_user
end
