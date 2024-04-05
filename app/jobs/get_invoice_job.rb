require 'faraday'

class GetInvoiceJob < ApplicationJob
  queue_as :default

  def perform(cloud_service_config, team, invoice_id, **options)
    runner = Runner.new(
      team: team,
      invoice_id: invoice_id,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result < InvoiceBaseJob::Result
    validate do
      unless @invoice.is_a?(Invoice) && @invoice.valid?
        errors.add(:invoice, message: "failed to parse")
      end
    end

    def invoice
      success? ? @invoice : nil
    end

    private

    def parse_body(body)
      @invoice = parse_invoice(body["invoice"])
    end
  end

  class Runner < InvoiceBaseJob::Runner
    def initialize(team:, invoice_id:, **kwargs)
      @team = team
      @invoice_id = invoice_id
      super(**kwargs)
    end

    private

    def fake_response
      renderer = ::ApplicationController.renderer.new
      data = renderer.render(
        template: "invoices/fakes/#{@invoice_id}",
        layout: false,
        locals: {account_id: @team.billing_acct_id},
      )
      build_fake_response(
        success: true,
        status: 200,
        body: {"account_invoice" => JSON.parse(data)},
      )
    rescue ActionView::MissingTemplate
      build_fake_response(
        success: false,
        status: 404,
        body: {"error" => "Invoice Not Found"},
        reason_phrase: "Invoice Not Found",
      )
    end

    def url
      url = URI(@cloud_service_config.user_handler_base_url)
      url.path = "/get_account_invoice"
      url.to_s
    end

    def body
      {
        invoice: {
          billing_acct_id: @team.billing_acct_id,
          invoice_id: @invoice_id,
        },
      }
    end
  end
end
