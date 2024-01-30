require 'faraday'

class UserSignupJob < ApplicationJob
  queue_as :default

  retry_on ::Faraday::Error, wait: :polynomially_longer, attempts: 10
  retry_on ::ActiveModel::ValidationError, wait: :polynomially_longer, attempts: 10

  def perform(user, cloud_service_config, **options)
    if user.deleted_at
      logger.info("Skipping job; user was deleted at #{user.deleted_at.inspect}")
      return
    end
    runner = Runner.new(
      user: user,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    include HttpRequests::ResultSyncer

    property :cloud_user_id, from: :user_id, context: :cloud
    validates :cloud_user_id, presence: true, on: :cloud
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(user:, **kwargs)
      @user = user
      super(**kwargs)
    end

    def call
      response = super
      result = Result.from(response.body)
      result.validate!(:cloud)
      result.sync(@user, :cloud)
    rescue ::ActiveModel::ValidationError
      @logger.warn("Failed to sync response to user: #{$!.message}")
      raise
    end

    private

    def url
      "#{@cloud_service_config.user_handler_base_url}/create_user"
    end

    def body
      {
        cloud_env: {
          auth_url: @cloud_service_config.internal_auth_url,
          user_id: @cloud_service_config.admin_user_id,
          password: @cloud_service_config.admin_foreign_password,
          project_id: @cloud_service_config.admin_project_id,
        },
        username: @user.login,
        password: @user.foreign_password,
        email: @user.email
      }
    end
  end
end
