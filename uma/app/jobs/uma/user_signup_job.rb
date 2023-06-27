require 'faraday'

class Uma::UserSignupJob < Uma::ApplicationJob
  queue_as :default

  def perform(user, **options)
    runner = Runner.new(
      user: user,
      fleece_config: Fleece::Config.first,
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
        GoodJob.logger.info("Failed: #{msg}")
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
      }
    end
  end
end
