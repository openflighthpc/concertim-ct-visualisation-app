require 'faraday'

class CreateCreditDepositJob < ApplicationJob
  queue_as :default

  def perform(credit_deposit, cloud_service_config, user, **options)
    runner = Runner.new(
      credit_deposit: credit_deposit,
      user: user,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    def initialize(success, error_message, status_code=nil)
      @success = !!success
      @error_message = error_message
      @status_code = status_code
    end

    def success?
      @success
    end

    def error_message
      success? ? nil : @error_message
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(credit_deposit:, user:, **kwargs)
      @credit_deposit = credit_deposit
      @user = user
      super(**kwargs)
    end

    def call
      response = connection.post(path, body)
      unless response.success?
        return Result.new(false, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      details = response.body["credits"]
      puts details
      Result.new(true, "")
    rescue Faraday::Error
      status_code = $!.response[:status] rescue 0
      Result.new(false, $!.message, status_code)
    end

    private

    def url
      @cloud_service_config.user_handler_base_url
    end

    def path
      "/add_credits"
    end

    def body
      {
        cloud_env: cloud_env_details,
        credits: credits_details
      }
    end

    def credits_details
      {
        billing_account_id: @credit_deposit.billing_acct_id,
        credits_to_add: @credit_deposit.amount
      }
    end

    def cloud_env_details
      {
        auth_url: @cloud_service_config.internal_auth_url,
        user_id: @cloud_service_config.admin_user_id,
        password: @cloud_service_config.admin_foreign_password,
        project_id: @cloud_service_config.admin_project_id,
      }
    end
  end
end
