require 'faraday'

class GetInvoicesJob < ApplicationJob
  queue_as :default

  def perform(cloud_service_config, team, **options)
    runner = Runner.new(
      team: team,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result < InvoiceBaseJob::Result
    attr_reader :invoices_count

    validates :invoices_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}
    validate do
      unless @invoices.is_a?(Array) && @invoices.all? { |invoice| invoice.valid? }
        errors.add(:invoices, message: "failed to parse")
      end
    end

    def invoices
      success? ? @invoices : nil
    end

    private

    def parse_body(body)
      parse_invoices_count(body)
      @invoices = body["invoices"].map { |data| parse_invoice(data) }
    end

    def parse_invoices_count(body)
      @invoices_count = body["total_invoices"]
      @invoices_count = Integer(@invoices_count) if @invoices_count.is_a?(String)
    rescue ArgumentError, TypeError
      # We don't need to do anything here the validation will catch this.
    end
  end

  class Runner < InvoiceBaseJob::Runner
    def initialize(team:, offset:, limit:, **kwargs)
      @team = team
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
        locals: {account_id: @team.billing_acct_id},
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
          billing_account_id: @team.billing_acct_id,
          offset: @offset,
          limit: @limit,
        },
      }
    end
  end
end
