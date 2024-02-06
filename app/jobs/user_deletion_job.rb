require 'faraday'

class UserDeletionJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :default
  RETRY_ATTEMPTS = 10
  retry_on ::Faraday::Error, wait: :polynomially_longer, attempts: RETRY_ATTEMPTS

  # Allow only a single job for a given user and cloud platform.  Otherwise the
  # admin hammering the delete button will cause concertim to hammer the
  # middleware.
  good_job_control_concurrency_with(
    perform_limit: 1,
    enqueue_limit: 1,
    key: ->{ [self.class.name, arguments[0].to_gid.to_s, arguments[1].to_gid.to_s].join('--') },
  )

  def perform(user, cloud_service_config, **options)
    # If the user doesn't have any cloud or billing IDs we can just delete it
    # without involving the middleware.
    if user.cloud_user_id.nil? && user.project_id.nil? && user.billing_acct_id.nil?
      user.destroy!
      return
    end
    runner = Runner.new(
      user: user,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
    nil
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(user:, **kwargs)
      @user = user
      super(**kwargs.reverse_merge(test_stubs: test_stubs))
    end

    def test_stubs
      nil
    end

    def call
      response = connection.delete("") do |request|
        request.body = body
      end
      if response.success?
        @user.destroy!
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
          project_id: @user.project_id,
        }
      }
    end
  end
end
