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

    validates :user_handler_port,
      numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 65535 }

    validates :cluster_builder_port,
              numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 65535 }

    validates :project_name,
      presence: true,
      length: { maximum: 255 }

    validates :domain_name,
      presence: true,
      length: { maximum: 255 },
      format: {
        with: /\A[a-zA-Z0-9\-\_.]*\Z/,
        message: "can contain only alphanumeric characters, hyphens, dots and underscores."
      }


    ############################
    #
    # Public Instance Methods
    #
    ############################

    def auth_url
      "http://#{host_ip}:#{port}/v3"
    end

    def user_handler_url
      url = URI(auth_url)
      url.port = user_handler_port
      url.path = "/create_user_project"
      url.to_s
    end

    def cluster_builder_base_url
      url = URI(auth_url)
      url.port = cluster_builder_port
      url.path = ""
      url.to_s
    end
end
