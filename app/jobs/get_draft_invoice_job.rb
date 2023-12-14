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

  class Result < InvoiceBaseJob::Result
    def invoice
      success? ? @invoice : nil
    end

    private

    def parse_body(body, user)
      @invoice = parse_invoice(body["draft_invoice"], user)
    end

  end

  class Runner < InvoiceBaseJob::Runner
    def initialize(user:, **kwargs)
      @user = user
      super(**kwargs)
    end

    private

    def process_response(response)
      if response.status == 204
        result_klass.new(false, nil, nil, "Nothing to generate", response.status)
      else
        super
      end
    end

    def fake_response
      renderer = ::ApplicationController.renderer.new
      data = renderer.render(
        template: "invoices/fakes/draft",
        layout: false,
      )
      build_fake_response(
        success: true,
        status: 201,
        body: {"draft_invoice" => JSON.parse(data)},
      )
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
