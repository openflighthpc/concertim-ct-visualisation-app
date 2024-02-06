require 'faraday'

class CreateUserProjectJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  queue_as :default

  retry_on ::Faraday::Error, wait: :polynomially_longer, attempts: 10
  retry_on ::ActiveModel::ValidationError, wait: :polynomially_longer, attempts: 10

  # Allow only a single job for a given user
  good_job_control_concurrency_with(
    perform_limit: 1,
    enqueue_limit: 1,
    key: ->{ [self.class.name, arguments[0].to_gid.to_s, arguments[1].to_gid.to_s].join('--') },
    )

  def perform(user, cloud_service_config, **options)
    if user.deleted_at
      logger.info("Skipping job; user was deleted at #{user.deleted_at.inspect}")
      return
    end

    if user.project_id
      logger.info("Skipping job; user already has a project")
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

    property :project_id, context: :project
    validates :project_id, presence: true, on: :project
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(user:, **kwargs)
      @user = user
      super(**kwargs)
    end

    def call
      response = super
      result = Result.from(response.body)
      result.validate!(:project)
      result.sync(@user, :project)
    rescue ::ActiveModel::ValidationError
      @logger.warn("Failed to sync response to user: #{$!.message}")
      raise
    end

    private

    def url
      "#{@cloud_service_config.user_handler_base_url}/project"
    end

    def body
      {
        cloud_env: {
          auth_url: @cloud_service_config.internal_auth_url,
          user_id: @cloud_service_config.admin_user_id,
          password: @cloud_service_config.admin_foreign_password,
          project_id: @cloud_service_config.admin_project_id,
        },
        primary_user_cloud_id: @user.cloud_user_id
      }
    end
  end
end
