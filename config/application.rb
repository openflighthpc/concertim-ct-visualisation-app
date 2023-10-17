require_relative "boot"

require "rails/all"

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
    #
    #
    if ENV['CONCERTIM_JWT_SECRET'].present?
      config.jwt_secret_file = nil
      config.jwt_secret = ENV['CONCERTIM_JWT_SECRET'].chomp
    else
      config.jwt_secret_file = Pathname('/opt/concertim/etc/secret')
      config.jwt_secret = config.jwt_secret_file.read.chomp
    end
    config.jwt_aud = 'alces-ct'

    # The base URL to use for the concertim metric reporting daemon.
    config.metric_daemon_url = ENV.fetch("METRIC_DAEMON_URL", "http://localhost:3000")

    # Display a fake invoice if ENV['FAKE_INVOICE'] is set.  Otherwise the
    # concertim-openstack-service will be contacted to provide the invoice.
    config.fake_invoice = ENV['FAKE_INVOICE']
  end
end
