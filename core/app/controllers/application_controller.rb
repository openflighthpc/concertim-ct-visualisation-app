class ApplicationController < ActionController::Base
  include FakeAuthConcern
  helper_method :current_user
  helper_method :user_signed_in?
end
