require 'faraday'

class UserUpdateJob < ApplicationJob
  queue_as :default
  RETRY_ATTEMPTS = 10
  retry_on ::Faraday::Error, wait: :polynomially_longer, attempts: RETRY_ATTEMPTS

  def perform(user, changes, cloud_service_config, **options)
    # If the user doesn't have any cloud or billing IDs there is no need to involve the middleware.
    if user.cloud_user_id.nil? && user.billing_acct_id.nil?
      return
    end
    runner = Runner.new(
      user: user,
      changes: changes,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
    nil
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(user:, changes:, **kwargs)
      @user = user
      @changes = changes
      super(**kwargs.reverse_merge(test_stubs: test_stubs))
    end

    def test_stubs
      nil
    end

    def call
      response = connection.patch("", body)
      if response.success?
        @user.foreign_password = @user.pending_foreign_password
        @user.pending_foreign_password = nil
        @user.save!
      end
    end

    private

    def url
      url = URI(@cloud_service_config.user_handler_base_url)
      url.path = "/user"
      url.to_s
    end

    def body
      {
        cloud_env: {
          auth_url: @cloud_service_config.internal_auth_url,
          user_id: @cloud_service_config.admin_user_id,
          password: @cloud_service_config.admin_foreign_password,
          project_id: @cloud_service_config.admin_project_id,
        },
        user_info: {
          billing_acct_id: @user.billing_acct_id,
          cloud_user_id: @user.cloud_user_id,
          new_data: {}.tap do |h|
            h[:email] = @user.email if @changes[:email]
            h[:password] = @user.pending_foreign_password if @changes[:password]
          end,
        }
      }
    end
  end
end
