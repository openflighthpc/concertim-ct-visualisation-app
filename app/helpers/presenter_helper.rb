#
# PresenterHelper
#
# Helper methods related to presenters.
#
module PresenterHelper

  #
  # presenter_for
  #
  # Accepts any object, yields that object's presenter if given a block.
  # Regardless of whether a block is passed, this method will always return the
  # presenter.
  #
  # The method will try to infer the presenter from the class name, but also
  # allows you to pass it in as a second argument.
  #
  # Usage:
  #
  # <% presenter_for @user do |user_presenter| %>
  #   <%= user_presenter.title %>
  # <% end %>
  #
  def presenter_for(object, klass = nil)
    klass ||= "#{object.class}Presenter".constantize
    presenter = klass.new(object, self)
    yield presenter if block_given?
    presenter
  end
end
