class ApplicationController < ActionController::Base
  include ControllerConcerns::Authentication
  include ControllerConcerns::Authorization
end
