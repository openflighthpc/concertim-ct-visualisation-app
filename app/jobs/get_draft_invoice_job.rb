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
        @invoice = Invoice.new(account: user).tap do |invoice|
          (Invoice.attribute_names - %w(account items)).each do |attr|
            invoice.send("#{attr}=", invoice_data[attr] || invoice_data[attr.camelize(:lower)])
          end
          invoice_data["items"].each do |item_data|
            invoice.items << Invoice::Item.new.tap do |item|
              Invoice::Item.attribute_names.each do |attr|
                item.send("#{attr}=", item_data[attr] || item_data[attr.camelize(:lower)])
              end
            end
          end
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
      data = renderer.render(
        template: "invoices/fake",
        layout: false,
      )
      invoice = JSON.parse(data)
      Object.new.tap do |o|
        o.define_singleton_method(:success?) { true }
        o.define_singleton_method(:status) { 201 }
        o.define_singleton_method(:body) { {"draft_invoice" => invoice} }
      end
    end

    def url
      url = URI(@cloud_service_config.user_handler_base_url)
      url.path = "/get_draft_invoice"
      url.to_s
    end

    def body
      {
        invoice: {
          billing_account_id: @user.billing_acct_id,
          target_date: Date.today.to_formatted_s(:iso8601),
        },
      }
    end
  end
end
