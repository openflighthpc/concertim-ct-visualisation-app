require 'faraday'

class GetInvoiceJob < ApplicationJob
  queue_as :default

  def perform(cloud_service_config, user, invoice_id, **options)
    runner = Runner.new(
      user: user,
      invoice_id: invoice_id,
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
        @invoice = parse_invoice(invoice_data, user)
      end
    end

    def parse_invoice(invoice_data, user)
      Invoice.new(account: user).tap do |invoice|
        (invoice.attribute_names - %w(account items)).each do |attr|
          invoice.send("#{attr}=", invoice_data[attr] || invoice_data[attr.camelize(:lower)])
        end
        invoice_data["items"].each do |item_data|
          invoice.items << Invoice::Item.new.tap do |item|
            item.attribute_names.each do |attr|
              item.send("#{attr}=", item_data[attr] || item_data[attr.camelize(:lower)])
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
    def initialize(user:, invoice_id:, **kwargs)
      @user = user
      @invoice_id = invoice_id
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
      return Result.new(true, response.body["invoice"], @user, "", response.status)

    rescue Faraday::Error
      status_code = $!.response[:status] rescue 0
      Result.new(false, nil, nil, $!.message, status_code)
    end

    private

    def fake_response
      renderer = ::ApplicationController.renderer.new
      data = renderer.render(
        template: "invoices/fakes/#{@invoice_id}",
        layout: false,
      )
      invoice = JSON.parse(data)
      Object.new.tap do |o|
        o.define_singleton_method(:success?) { true }
        o.define_singleton_method(:status) { 200 }
        o.define_singleton_method(:body) { {"invoice" => invoice} }
      end
    end

    def url
      url = URI(@cloud_service_config.user_handler_base_url)
      url.path = "/get_account_invoice/#{@invoice_id}"
      url.to_s
    end

    def body
      {
        invoice: {
          billing_account_id: @user.billing_acct_id,
          invoice_id: @invoice_id,
        },
      }
    end
  end
end
