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
    if ENV['JWT_SECRET'].present?
      config.jwt_secret = ENV['JWT_SECRET'].chomp
    else
      jwt_secret_file = Pathname(ENV.fetch('JWT_SECRET_FILE', '/opt/concertim/etc/secret'))
      if File.exist?(jwt_secret_file)
        config.jwt_secret = jwt_secret_file.read.chomp
      else
        config.jwt_secret = nil
      end
    end
    config.jwt_aud = 'alces-ct'

    # The base URL to use for the concertim metric reporting daemon.
    config.metric_daemon_url = ENV.fetch("METRIC_DAEMON_URL", "http://localhost:3000/")

    # Display a fake invoice if ENV['FAKE_INVOICE'] is set.  Otherwise the
    # concertim-openstack-service will be contacted to provide the invoice.
    config.fake_invoice = ENV['FAKE_INVOICE']

    # Support storing credentials content on a docker volume.  This allows
    # per-site credentials and master key to be provided.
    if ENV['CREDENTIALS_CONTENT_PATH'].present?
      config.credentials.content_path = Pathname.new(ENV['CREDENTIALS_CONTENT_PATH'])
    end
    if ENV['CREDENTIALS_KEY_PATH'].present?
      config.credentials.key_path = Pathname.new(ENV['CREDENTIALS_KEY_PATH'])
    end

    config.dartsass.builds = {
      "application.scss" => "application.css",
      "irv.scss" => "irv.css",
    }

    # config.require_master_key = true
  end
end
