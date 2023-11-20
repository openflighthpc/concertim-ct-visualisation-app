require 'faraday'

class GetDraftInvoiceJob < ApplicationJob
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

    def initialize(success, invoice_data, user, error_message, status_code=nil)
      @success = !!success
      @error_message = error_message
      @status_code = status_code
      if success? && !invoice_data.nil?
        @invoice = Invoice.new(
          account: user,
          amount: invoice_data["amount"],
          amount_paid: invoice_data["amount_paid"],
          balance: invoice_data["balance"],
          currency: invoice_data["currency"],
          invoice_date: invoice_data["invoice_date"],
          invoice_id: invoice_data["invoice_id"],
          invoice_number: invoice_data["invoice_number"],
        )
        invoice_data["items"].each do |item|
          @invoice.items << Invoice::Item.new(
            amount: item["amount"],
            currency: item["currency"],
            description: item["description"],
            end_date: item["end_date"],
            plan_name: item["plan_name"],
            start_date: item["start_date"],
          )
        end
      end
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
      response =
        if Rails.application.config.fake_invoice
          fake_response
        else
          super
        end
      unless response.success?
        return Result.new(false, nil, nil, response.reason_phrase || "Unknown error")
      end
      return Result.new(true, response.body["draft_invoice"], @user, "", response.status)

    rescue Faraday::Error
      status_code = $!.response[:status] rescue 0
      Result.new(false, nil, nil, $!.message, status_code)
    end

    private

    def fake_response
      renderer = ::ApplicationController.renderer.new
      invoice = renderer.render(
        template: "invoices/fake",
        layout: false,
        assigns: {user: UserPresenter.new(@user)},
      )
      Object.new.tap do |o|
        o.define_singleton_method(:success?) { true }
        o.define_singleton_method(:status) { 201 }
        o.define_singleton_method(:body) { {"invoice_html" => invoice} }
      end
    end

    def url
      url = URI(@cloud_service_config.user_handler_base_url)
      url.path = "/get_draft_invoice"
      url.to_s
    end

    def body
      {
        cloud_env: {
          auth_url: @cloud_service_config.internal_auth_url,
          user_id: @user.cloud_user_id,
          password: @user.foreign_password,
          project_id: @user.project_id,
        },
        invoice: {
          billing_acct_id: @user.billing_acct_id,
          target_date: Date.today.to_formatted_s(:iso8601),
        },
      }
    end
  end
end
