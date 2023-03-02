class ApplicationController < ActionController::Base
  include Emma::ControllerConcerns::Authentication
  include Emma::ControllerConcerns::Authorization
end
