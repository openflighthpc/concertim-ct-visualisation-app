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

  class Result < InvoiceBaseJob::Result
    def invoice
      success? ? @invoice : nil
    end

    private

    def parse_body(body, user)
      @invoice = parse_invoice(body["account_invoice"], user)
    end
  end

  class Runner < InvoiceBaseJob::Runner
    def initialize(user:, invoice_id:, **kwargs)
      @user = user
      @invoice_id = invoice_id
      super(**kwargs)
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
        o.define_singleton_method(:body) { {"account_invoice" => invoice} }
      end
    rescue ActionView::MissingTemplate
      Object.new.tap do |o|
        o.define_singleton_method(:success?) { false }
        o.define_singleton_method(:status) { 404 }
        o.define_singleton_method(:body) { {"error" => "Invoice Not Found"} }
        o.define_singleton_method(:reason_phrase) { "Invoice Not Found" }
      end
    end

    def url
      url = URI(@cloud_service_config.user_handler_base_url)
      url.path = "/get_account_invoice"
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
