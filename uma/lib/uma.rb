require "uma/version"
require "uma/engine"

require 'devise'
require 'dry-configurable'

module Uma
  extend Dry::Configurable

  setting :access_token_secret_file,
    default: '/data/private/share/daemons/ct-metric-reporting-daemon/config/secret',
    constructor: ->(value){ Pathname(value) }

  setting :access_token_secret,
    constructor: ->(value){ value.nil? ? config.access_token_secret_file.read.chomp : value }
end
