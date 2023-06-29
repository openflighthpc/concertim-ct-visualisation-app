require 'faraday'

class Uma::UserSignupJob < Uma::ApplicationJob
  class FailedJob < RuntimeError ; end

  queue_as :default

  retry_on FailedJob, wait: :exponentially_longer, attempts: 10
  retry_on ::Faraday::Error, wait: :exponentially_longer, attempts: 10

  def perform(user, fleece_config, **options)
    runner = Runner.new(
      user: user,
      fleece_config: fleece_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Runner < Emma::Faraday::JobRunner
    def initialize(user:, **kwargs)
      @user = user
      super(**kwargs)
    end

    def call
      response = super
      unless response.success?
        msg = response.reason_phrase || "Unkown error"
        @logger.info("Failed: #{msg}")
        raise FailedJob, msg
      end
    end

    private

    def url
      @fleece_config.user_handler_url
    end

    def body
      {
        cloud_env: {
          auth_url: @fleece_config.auth_url,
          username: "admin",
          password: @fleece_config.password,
          project_name: @fleece_config.project_name,
          user_domain_name: @fleece_config.domain_name,
          project_domain_name: @fleece_config.domain_name,
        },
        username: @user.login,
        password: @user.fixme_encrypt_this_already_plaintext_password,
      }.tap do |h|
          h[:project_id] = @user.project_id unless @user.project_id.blank?
        end
    end
  end
end
