require 'resolv'

class Fleece::Config < ApplicationRecord
    ############################
    #
    # Validations
    #
    ############################

    validates :host_name,
      presence: true,
      length: { maximum: 255 },
      format: {
        with: /\A[a-zA-Z0-9\-\_.]*\Z/,
        message: "can contain only alphanumeric characters, hyphens, dots and underscores."
      }

    validates :host_ip,
      presence: true,
      length: { maximum: 255 },
    format: { with: Regexp.new("#{Resolv::IPv4::Regex}|#{Resolv::IPv6::Regex}") }

    validates :username,
      presence: true,
      length: { maximum: 255 }

    validates :password,
      presence: true,
      length: { maximum: 255 }

    validates :port,
      numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 65535 }

    validates :project_name,
      presence: true,
      length: { maximum: 255 }

    validates :domain_name,
      presence: true,
      length: { maximum: 255 },
      format: {
        with: /\A[a-zA-Z0-9\-\_]*\Z/,
        message: "can contain only alphanumeric characters, hyphens and underscores."
      }

end
