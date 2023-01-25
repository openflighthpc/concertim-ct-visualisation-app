# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

app = Rack::Builder.new do
  map "/--" do
    run Rails.application
  end
end
run app

Rails.application.load_server
