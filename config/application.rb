#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

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

    # minimum credits user must have to create a cluster
    config.after_initialize do
      config.cluster_credit_requirement = if ENV['CLUSTER_CREDIT_REQUIREMENT']
        begin
          config.cluster_credit_requirement = Float(ENV['CLUSTER_CREDIT_REQUIREMENT'])
        rescue ArgumentError
          msg = 'ENV variable CLUSTER_CREDIT_REQUIREMENT is not a valid number. Please update its value, or unset it.'
          Rails.logger.warn(msg)
          $stderr.puts(msg)
          exit(1)
        end
      else
        25
      end
    end

    # config.require_master_key = true
  end
end
