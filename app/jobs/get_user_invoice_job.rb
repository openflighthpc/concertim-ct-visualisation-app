require 'faraday'

class GetUserInvoiceJob < ApplicationJob
  queue_as :default

  def perform(cloud_service_config, user, **options)
    runner = Runner.new(
      user: user,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    attr_reader :status_code

    def initialize(success, invoice, error_message, status_code=nil)
      @success = !!success
      @invoice = invoice
      @error_message = error_message
      @status_code = status_code
    end

    def success?
      @success
    end

    def invoice
      success? ? @invoice : nil
    end

    def error_message
      success? ? nil : @error_message
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(user:, **kwargs)
      @user = user
      super(**kwargs)
    end

    def call
      return fake_response

      response = connection.get(path) do |req|
        req.body = body
      end
      unless response.success?
        return Result.new(false, nil, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      return Result.new(true, response.body, "", response.status)

    rescue Faraday::Error
      status_code = $!.response[:status] rescue 0
      Result.new(false, nil, $!.message, status_code)
    end

    private

    def fake_response
      renderer = ::ApplicationController.renderer.new
      invoice = renderer.render(
        template: "invoices/fake",
        layout: false,
        assigns: {user: UserPresenter.new(@user)},
      )
      Result.new(true, invoice, "", 200)
    end

    def url
      @cloud_service_config.user_handler_base_url
    end

    def path
      "/get_user_invoice"
    end

    def error_description
      "Unable to fetch user's invoice"
    end

    def body
      {
        cloud_env: {
          auth_url: @cloud_service_config.internal_auth_url,
          user_id: @user.cloud_user_id,
          password: @user.foreign_password,
          project_id: @user.project_id,
          billing_acct_id: @user.billing_acct_id,
        }
      }
    end
  end
end

