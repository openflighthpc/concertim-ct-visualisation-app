require 'resolv'

class Fleece::Config < ApplicationRecord
    ############################
    #
    # Validations
    #
    ############################

    validates :admin_user_id,
              presence: true,
              length: { maximum: 255 }

    validates :admin_password,
              presence: true,
              length: { maximum: 255 }

    validates :admin_project_id,
              presence: true,
              length: { maximum: 255 }

    validates :user_handler_port,
              numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 65535 }

    validates :cluster_builder_port,
              numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 65535 }

    validates :host_url, presence: true
    validates :host_url, format: { with: URI.regexp, message: 'must be a valid url' }, allow_blank: true

    validates :internal_auth_url, presence: true
    validates :internal_auth_url, format: { with: URI.regexp, message: 'must be a valid url' }, allow_blank: true

    ############################
    #
    # Public Instance Methods
    #
    ############################

    def user_handler_base_url
      url = URI(host_url)
      url.port = user_handler_port
      url.path = ""
      url.to_s
    end

    def cluster_builder_base_url
      url = URI(host_url)
      url.port = cluster_builder_port
      url.path = ""
      url.to_s
    end
end
