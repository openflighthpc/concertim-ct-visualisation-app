require 'resolv'

class CloudServiceConfig < ApplicationRecord
    encrypts :admin_foreign_password

    ############################
    #
    # Validations
    #
    ############################

    validates :admin_user_id,
              presence: true,
              length: { maximum: 255 }

    validates :admin_foreign_password,
              presence: true,
              length: { maximum: 255 }

    validates :admin_project_id,
              presence: true,
              length: { maximum: 255 }

    validates :user_handler_base_url, presence: true
    validates :user_handler_base_url, format: { with: URI.regexp, message: 'must be a valid url' }, allow_blank: true

    validates :cluster_builder_base_url, presence: true
    validates :cluster_builder_base_url, format: { with: URI.regexp, message: 'must be a valid url' }, allow_blank: true

    validates :internal_auth_url, presence: true
    validates :internal_auth_url, format: { with: URI.regexp, message: 'must be a valid url' }, allow_blank: true
end
