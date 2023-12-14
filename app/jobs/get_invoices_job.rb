require 'faraday'

class GetInvoicesJob < ApplicationJob
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
    attr_reader :invoices_count

    def invoices
      success? ? @invoices : nil
    end

    private

    def parse_body(body, user)
      @invoices_count = body["total_invoices"]
      @invoices_count = Integer(@invoices_count) if @invoices_count.is_a?(String)
      @invoices = body["invoices"].map { |data| parse_invoice(data, user) }
    end
  end

  class Runner < InvoiceBaseJob::Runner
    def initialize(user:, offset:, limit:, **kwargs)
      @user = user
      @offset = offset
      @limit = limit
      super(**kwargs)
    end

    private

    def fake_response
      renderer = ::ApplicationController.renderer.new
      data = renderer.render(
        template: "invoices/fakes/list",
        layout: false,
      )
      body = JSON.parse(data)
      # Return a slice of all invoices just as the real API does.
      body["invoices"] = body["invoices"][@offset, @limit]
      build_fake_response(success: true, status: 200, body: body)
    end

    def url
      url = URI(@cloud_service_config.user_handler_base_url)
      url.path = "/list_paginated_invoices"
      url.to_s
    end

    def body
      {
        invoices: {
          billing_account_id: @user.billing_acct_id,
          offset: @offset,
          limit: @limit,
        },
      }
    end
  end
end
