require "uma/version"
require "uma/engine"

require 'devise'
require 'dry-configurable'

module Uma
  extend Dry::Configurable

  setting :jwt_secret_file,
    default: '/opt/concertim/etc/secret',
    constructor: ->(value){ Pathname(value) }

  setting :jwt_secret,
    constructor: ->(value){ value.nil? ? config.jwt_secret_file.read.chomp : value }

  setting :jwt_aud,
    default: 'alces-ct'
end
