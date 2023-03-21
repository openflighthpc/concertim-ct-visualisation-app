require_relative "boot"

require "rails/all"

# XXX What's the right way to do this.  We need to load it at some point so
# that the autoloads it defines works.  This ought to be done after the load
# paths have been set.
require_relative "../app/lib/emma"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CtApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end

CtApp::Application::configure do
  config.after_initialize do

    #
    # When the good job worker process starts enqueue a job to preheat the
    # interchange.
    #
    if ENV['GOOD_JOB_WORKER'] && ENV['GOOD_JOB_WORKER'] == "true"
      Emma::PreheatJob.set(priority: -10).perform_later(Ivy)
    end
  end
end
