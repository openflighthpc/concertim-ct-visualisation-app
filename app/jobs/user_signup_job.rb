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

    property :cloud_user_id, from: :cloud_id, context: :cloud
    validates :cloud_user_id, presence: true, on: :cloud

    property :billing_acct_id, context: :billing
    validates :billing_acct_id, presence: true, on: :billing
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

      if @user.cloud_user_id_changed? && !@user.project_id
        CreateUserProjectJob.perform_later(@user, @cloud_service_config)
      end

      result.validate!(:billing)
      result.sync(@user, :billing)
    rescue ::ActiveModel::ValidationError
      @logger.warn("Failed to sync response to user: #{$!.message}")
      raise
    end

    private

    def url
      "#{@cloud_service_config.user_handler_base_url}/user"
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
      }.tap do |h|
          h[:cloud_id] = @user.cloud_user_id unless @user.cloud_user_id.blank?
          h[:billing_acct_id] = @user.billing_acct_id unless @user.billing_acct_id.blank?
        end
    end
  end
end
