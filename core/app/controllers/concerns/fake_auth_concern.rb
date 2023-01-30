module FakeAuthConcern
  extend ActiveSupport::Concern

  included do
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
